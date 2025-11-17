# https://tpm2-software.github.io/2020/04/13/Disk-Encryption.html
# https://en.opensuse.org/Portal:MicroOS/FDE
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/

apk_new add systemd-boot

apk_new add kernel-hooks mkinitfs tpm2-tools
echo 'disable_trigger=yes' >> "$new_root"/etc/mkinitfs/mkinitfs.conf

case "$(cat /etc/apk/arch)" in
	x86*) apk_new add amd-ucode intel-ucode;;
esac
# if the installation target in not removable, find if current cpu is amd or intel, and only install that ucode

cat <<-'EOF' > "$new_root"/etc/kernel-hooks.d/pcr-policy.hook
#!/usr/bin/env sh
set -euo pipefail

readonly NEW_VERSION=$2

# hook triggered for the kernel removal, nothing to do here
[ "$NEW_VERSION" ] || exit 0

efi_name="$(ls /usr/lib/systemd/boot/efi/system-boot*.efi | sed -n "s@/usr/lib/systemd/boot/efi/system-@@p")"
[ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] &&
	mv /usr/lib/systemd/boot/efi/system-boot*.efi /boot/efi/boot/"$efi_name"

/boot/vmlinuz-stable /boot/loader/entries/vmlinuz.efi

root_fs_uuid=
cmdline="root=UUID=$root_fs_uuid ro modules=sd-mod,usb-storage,btrfs,nvme quiet rootfstype=btrfs"

# get digest of systemd-boot.efi

# get digest of initrds (including microcodes)

[ -f /boot/amd-ucode.img ] && mv /boot/amd-ucode.img /boot/loader/entries/
[ -f /boot/intel-ucode.img ] &&
if [ -f /boot/loader/entries/amd-ucode.img ]; then
	# calculate its sha256 sum, and put it in initramfs_sum
fi
if [ -f /boot/loader/entries/intel-ucode.img ]; then
	# calculate its sha256 sum, and add it to the value of initramfs_sum
fi

mkinitfs -o /boot/initramfs "$NEW_VERSION-stable"
# https://gitlab.alpinelinux.org/alpine/mkinitfs
# in initrd, use /boot/pcrsig (in efi partition) to unseal the luks key
# try /boot/pcrsig.old if that failed
# if failed again, warn the user that the system is tampered with
# 	ask the user to enter password only if she is sure that the source of tamper is herself
# calculate its sha256 sum, and add it to the value of initramfs_sum

# efi_apps_sum
# sha256 sum of the sentence "Calling EFI Application from Boot Option"
# plus sha256 sum of the sentence "Calling EFI Application from Boot Option"
# plus sha256 sum of /boot/efi/boot/"$efi_name"
# plus sha256 sum of /boot/loader/entries/vmlinuz.efi

# sha256 sum of loader/loader.conf as pcr5 digest

# initramfs_sum as pcr9 digest

# cmd_line_sum as pcr12 digest

# if there is no /boot/keys/priv /boot/keys/pub
# use a public/private key pair (RSA2048) to generate a TPM2 signed PCR policy,
# 	to keep the LUKS key used to encrypt root partition
# create a key pair (only readable by root): /boot/keys/priv /boot/keys/pub
# create a policy, associated with the public key

# sign the result with the private key, and store the signature in /boot/pcrsig
# 	while keeping the old one in /boot/pcrsig.old
EOF
chmod +x "$new_root"/etc/kernel-hooks.d/pcr-policy.hook

# regenerate pcr policy, when systemd-boot or ucodes are updated
# apk hook after commit:
# [ -f /boot/amd-ucode.img] || [ -f /boot/intel-ucode.img] || [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] &&
# /etc/kernel-hooks.d/pcr-policy.hook

apk_new add linux-stable
