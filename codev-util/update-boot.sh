#!/usr/bin/env sh

new_kernel_version="$2"

# hook triggered for the kernel removal, nothing to do here
[ "$new_kernel_version" ] || exit 0

efi_name="$(ls /usr/lib/systemd/boot/efi/system-boot*.efi | sed -n "s@/usr/lib/systemd/boot/efi/system-@@p")"
if [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ]; then
	mv /usr/lib/systemd/boot/efi/system-boot*.efi /boot/efi/boot-new/"$efi_name"
else
	cp /boot/efi/boot/"$efi_name" /boot/efi/boot-new/
fi

if [ -f /boot/vmlinuz* ]; then
	mv /boot/vmlinuz-stable /boot/efi/boot-new/vmlinuz
else
	cp /boot/efi/boot/vmlinuz /boot/efi/boot-new/
fi

# efi_apps_sum as the digest of pcr4:
# sha256 sum of the sentence "Calling EFI Application from Boot Option":
# 	3d6772b4f84ed47595d72a2c4c5ffd15f5bb72c7507fe26f2aaee2c69d5633ba
# plus sha256 sum of 0x00000000 (32 bits of zeros): df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119
# plus sha256 sum of /boot/efi/boot-new/"$efi_name"
# plus sha256 sum of /boot/efi/boot-new/vmlinuz
# https://github.com/grawity/tpm_futurepcr#usage
# https://github.com/grawity/tpm_futurepcr/blob/main/tpm_futurepcr/__init__.py


if [ -f /boot/amd-ucode.img ]; then
	mv /boot/amd-ucode.img /boot/efi/boot-new/ucode.img
elif [ -f /boot/efi/boot/ucode.img ]; then
	cp /boot/efi/boot/ucode.img /boot/efi/boot-new/ucode.img
fi
if [ -f /boot/intel-ucode.img ]; then
	mv /boot/amd-ucode.img /boot/efi/boot-new/ucode.img
elif [ -f /boot/efi/boot/ucode.img ]; then
	cp /boot/efi/boot/ucode.img /boot/efi/boot-new/ucode.img
fi

initfs_features="ata base nvme scsi usb mmc virtio btrfs cryptsetup tpm"
[ "$(uname -m)" = "aarch64" ] && initfs_features="$initfs_features phy"
mkinitfs -P /usr/local/share/mkinitfs/features -F "$initfs_features" \
	-o /boot/efi/boot-new/initramfs "${new_kernel_version}-stable"

initramfs_sum="$(cat /boot/efi/boot-new/ucode.img /boot/efi/boot-new/initramfs | sha256sum)"
# initramfs_sum as pcr9 digest

cmdline=
cat /boot/loader/entries/alpine.conf | grep '^options' | sed "s/^options[[:space:]]+//p" | while read -r option; do
	if [ -n "$cmdline" ]; then
		cmdline="$option"
	elif [ -n "$option" ]; then
		cmdline="$cmdline $option"
	fi
done
cmdline_sum=
# cmd_line_sum as pcr12 digest

# boot entry: usrflags=subvol=usr0 or usr1

# measured boot (instead of secure boot)
# if there is no /boot/keys/priv /boot/keys/pub
# use a public/private key pair (RSA2048) to generate a TPM2 signed PCR policy,
# 	to keep the LUKS key used to encrypt root partition
# create a key pair (only readable by root): /boot/keys/priv /boot/keys/pub
# create a policy, associated with the public key
# https://tpm2-software.github.io/2020/04/13/Disk-Encryption.html
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/

if [ ! -f signing_key_private.pem ]; then
	# create pcr policy
	tpm2_startauthsession -S session.ctx
	tpm2_policypcr -Q -S session.ctx -l sha256:0 -L set2.pcr.policy
	tpm2_flushcontext session.ctx
	# create signing authority for signing the policies and provision public key in system
	openssl genrsa -out signing_key_private.pem 2048
	openssl rsa -in signing_key_private.pem -out signing_key_public.pem -pubout
	# now we need the name which is a digest of the TCG public key format of the public key to include in the policy
	tpm2_loadexternal -G rsa -C o -u signing_key_public.pem -c signing_key.ctx -n signing_key.name
	# create authorized policy for creating the sealing object (create the signer policy)
	tpm2_startauthsession -S session.ctx
	tpm2_policyauthorize -S session.ctx -L authorized.policy -n signing_key.name -i set2.pcr.policy
	tpm2_flushcontext session.ctx
	# create secure passphrase and seal to the sealing object
	cat /var/lib/luks/key1 |
		tpm2_create -g sha256 -u auth_pcr_seal_key.pub -r auth_pcr_seal_key.priv -i- -C prim.ctx -L authorized.policy
	
	# tpm2_nvwrite
	
	tpm2_createpolicy -P -L sha1:4,9,12 -f policy.digest
	tpm2_createprimary -H e -g sha1 -G rsa -C primary.context
	tpm2_create -g sha256 -G keyedhash -u obj.pub -r obj.priv -c primary.context -L policy.digest \
		-A "noda|adminwithpolicy|fixedparent|fixedtpm" -I secret.bin
	tpm2_load -c primary.context -u obj.pub -r obj.priv -C load.context
	tpm2_evictcontrol -c load.context -A o -S 0x81000000
	rm load.context obj.priv obj.pub policy.digest primary.context
fi

# sign valid pcr policies and provide the policy and the signature (sign the pcr_policy with the signer private key)
openssl dgst -sha256 -sign signing_key_private.pem -out set2.pcr.signature set2.pcr.policy

# sign the result with the private key, and store the signature in /boot/pcrsig

if [ -e /boot/efi/boot ]; then
	# exch /boot/efi/boot-new /boot/efi/boot
else
	mv /boot/efi/boot-new /boot/efi/boot
fi
