# https://news.opensuse.org/2025/07/18/fde-rogue-devices/
# https://microos.opensuse.org/blog/2023-12-20-sdboot-fde/
# https://en.opensuse.org/Portal:MicroOS/FDE
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/
# https://wiki.archlinux.org/title/Unified_kernel_image
# https://gitlab.alpinelinux.org/alpine/mkinitfs
# https://wiki.archlinux.org/title/Microcode
# UKI with a signed TPM2 policy
# https://0pointer.net/blog/brave-new-trusted-boot-world.html

apk_new add kernel-hooks mkinitfs tpm2-tools stubbyboot-efistub efi-mkuki
case "$(cat /etc/apk/arch)" in
	x86*) apk_new add amd-ucode intel-ucode;;
esac

cat <<-'EOF' > "$new_root"/etc/kernel-hooks.d/uki.hook
#!/usr/bin/env sh
set -euo pipefail

readonly NEW_VERSION=$2

# hook triggered for the kernel removal, nothing to do here
[ "$NEW_VERSION" ] || exit 0

root_fs_uuid=
cmdline="root=UUID=$root_fs_uuid ro modules=sd-mod,usb-storage,btrfs,nvme quiet rootfstype=btrfs"

case "$(cat /etc/apk/arch)" in
	aarch64) readonly MARCH="aa64";;
	arm*)    readonly MARCH="arm";;
	riscv64) readonly MARCH="riscv64";;
	x86)     readonly MARCH="ia32";;
	x86_64)  readonly MARCH="x64";;
esac
efistub_path=/usr/lib/stubbyboot/linux${MARCH}.efi.stub
[ -f "$efistub_path" ] || efistub_path=/usr/lib/systemd/boot/efi/linux${MARCH}.efi.stub

microcode=
if [ -f /boot/amd-ucode.img ]; then
	microcode=/boot/amd-ucode.img
	[ -f /boot/intel-ucode.img ] && microcode="$microcode /boot/intel-ucode.img"
else
	[ -f /boot/intel-ucode.img ] && microcode=/boot/intel-ucode.img
fi

tmpdir=$(mktemp -dt "uki")
trap "rm -f '$tmpdir'/*; rmdir '$tmpdir'" EXIT HUP INT TERM

mkinitfs -o "$tmpdir"/initramfs "$NEW_VERSION-stable"
echo 'disable_trigger=yes' >> "$new_root"/etc/mkinitfs/mkinitfs.conf
# in initrd, use /mnt/boot/pcrsig (in efi partition) to unseal the luks key
# try /mnt/boot/pcrsig.old if that failed

efi-mkuki \
	-k "$NEW_VERSION-stable" \
	-c "$cmdline" \
	-S "$efistub_path" \
	-o /boot/uki.efi \
	/boot/vmlinuz-stable $microcode "$tmpdir"/initramfs

# TPM2 PCR4
# create a key pair (only readable by root): /boot/keys/priv /boot/keys/pub
# then create a policy for pcr4, using the public key, to keep the LUKS key used to encrypt root partition
# get the hash of uki, and sign it with the private key, and store the signature in /boot/pcrsig
# 	keep the old on in /boot/pcrsig.old
# mv /boot/uki.efi /boot/efi/boot/boot${MARCH}.efi
EOF
chmod +x "$new_root"/etc/kernel-hooks.d/uki.hook

# regenerate UKI, when efistub or ucodes are updated
#
# apk hook before commit:
# rm -f /var/cache/uki/*-ucode.img /var/cache/uki/linux*.efi.stub
# [ -f /boot/amd-ucode.img] && ln /boot/amd-ucode.img /var/cache/uki/
# [ -f /boot/intel-ucode.img] && ln /boot/intel-ucode.img /var/cache/uki/
# [ -f /usr/lib/stubbyboot/linux*.efi.stub ] && ln /usr/lib/stubbyboot/linux*.efi.stub /var/cache/uki/
#
# apk hook after commit:
# [ -f /boot/amd-ucode.img] && ! [ /boot/amd-ucode.img -ef /var/cache/uki/amd-ucode.img ] && uki_regen_required=true
# [ -f /boot/intel-ucode.img] && ! [ /boot/intel-ucode.img -ef /var/cache/uki/intel-ucode.img ] && uki_regen_required=true
# [ -f /usr/lib/stubbyboot/linux*.efi.stub ] && 
# 	! [ /usr/lib/stubbyboot/linux*.efi.stub -ef /var/cache/uki/linux*.efi.stub ] && uki_regen_required=true
# [ "$uki_regen_required$ = true ] && /etc/kernel-hooks.d/uki.hook
# rm -f /var/cache/uki/*-ucode.img /var/cache/uki/linux*.efi.stub

apk_new add linux-stable
