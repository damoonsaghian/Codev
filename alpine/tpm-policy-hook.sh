#!/usr/bin/env sh
set -euo pipefail

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

if [ -f /boot/amd-ucode.img ]; then
	mv /boot/amd-ucode.img /boot/efi/boot-new/amd-ucode.img
elif [ -f /boot/efi/boot/amd-ucode.img ]; then
	cp /boot/efi/boot/amd-ucode.img /boot/efi/boot-new/amd-ucode.img
fi
if [ -f /boot/intel-ucode.img ]; then
	mv /boot/amd-ucode.img /boot/efi/boot-new/amd-ucode.img
elif [ -f /boot/efi/boot/intel-ucode.img ]; then
	cp /boot/efi/boot/intel-ucode.img /boot/efi/boot-new/intel-ucode.img
fi
amd_ucode_paths=
intel_ucode_paths=
[ -f /boot/efi/boot-new/amd-ucode.img ] && amd_ucode_paths="/boot/efi/boot-new/amd-ucode.img"
[ -f /boot/efi/boot-new/intel-ucode.img ] && intel_ucode_paths="/boot/efi/boot-new/intel-ucode.img"

mkinitfs -o /boot/efi/boot-new/initramfs "${new_kernel_version}-stable"

initramfs_sum="$(cat "$amd_ucode_path" "$intel_ucode_path" /boot/efi/boot-new/initramfs | sha256sum)"
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

# if there is no /boot/keys/priv /boot/keys/pub
# use a public/private key pair (RSA2048) to generate a TPM2 signed PCR policy,
# 	to keep the LUKS key used to encrypt root partition
# create a key pair (only readable by root): /boot/keys/priv /boot/keys/pub
# create a policy, associated with the public key
# https://tpm2-software.github.io/2020/04/13/Disk-Encryption.html
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/
tpm2_createpolicy -P -L sha1:4,9,12 -f policy.digest
tpm2_createprimary -H e -g sha1 -G rsa -C primary.context
tpm2_create -g sha256 -G keyedhash -u obj.pub -r obj.priv -c primary.context -L policy.digest \
	-A "noda|adminwithpolicy|fixedparent|fixedtpm" -I secret.bin
tpm2_load -c primary.context -u obj.pub -r obj.priv -C load.context
tpm2_evictcontrol -c load.context -A o -S 0x81000000
rm load.context obj.priv obj.pub policy.digest primary.context

# to clear the old key
# tpm2_evictcontrol -H 0x81000000 -A o

# sign the result with the private key, and store the signature in /boot/pcrsig

if [ -e /boot/efi/boot ]; then
	# exch /boot/efi/boot-new /boot/efi/boot
else
	mv /boot/efi/boot-new /boot/efi/boot
fi
