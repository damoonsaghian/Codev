#!/usr/bin/env sh
set -euo pipefail

readonly NEW_VERSION=$2

# hook triggered for the kernel removal, nothing to do here
[ "$NEW_VERSION" ] || exit 0

efi_name="$(ls /usr/lib/systemd/boot/efi/system-boot*.efi | sed -n "s@/usr/lib/systemd/boot/efi/system-@@p")"
if [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ]; then
	mv /usr/lib/systemd/boot/efi/system-boot*.efi /boot/efi/boot-new/"$efi_name"
else
	cp /boot/efi/boot/"$efi_name" /boot/efi/boot-new/
fi

if [ -f /boot/vmlinuz* ]; then
	mv /boot/vmlinuz* /boot/efi/boot-new/vmlinuz
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
if [ -f /boot/efi/boot-new/amd-ucode.img ]; then
	# calculate its sha256 sum, and put it in initramfs_sum
fi
if [ -f /boot/efi/boot-new/intel-ucode.img ]; then
	# calculate its sha256 sum, and add it to the value of initramfs_sum
fi

mkinitfs -o /boot/initramfs "$NEW_VERSION-stable"
# https://gitlab.alpinelinux.org/alpine/mkinitfs
# in initrd, use /boot/pcrsig (in efi partition) to unseal the luks key
# try /boot/pcrsig.old if that failed
# if failed again, warn the user that the system is tampered with
# 	ask the user to enter password only if she is sure that the source of tamper is herself
# if unseal was successful but decryption of root is failed, it means that:
# , the root is replaced
# , the key based slot of luks header is corrupted
# so ask the user to connect a backup storage device
# then try to decrypt luks devices, and when successful, copy it luks header onto the corrupted one

# calculate sha256 sum of initramfs file, and add it to the value of initramfs_sum
# initramfs_sum as pcr9 digest

cmdline="$(cat /boot/loader/entries/alpine.conf | grep options | sed s/options//p)"
cmdline_sum=
# cmd_line_sum as pcr12 digest

# if there is no /boot/keys/priv /boot/keys/pub
# use a public/private key pair (RSA2048) to generate a TPM2 signed PCR policy,
# 	to keep the LUKS key used to encrypt root partition
# create a key pair (only readable by root): /boot/keys/priv /boot/keys/pub
# create a policy, associated with the public key

# sign the result with the private key, and store the signature in /boot/pcrsig
# 	while keeping the old one in /boot/pcrsig.old
