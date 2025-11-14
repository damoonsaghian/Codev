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

apk_new add kernel-hooks mkinitfs tpm2-tools efi-mkuki
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

efi-mkuki \
	-k "$NEW_VERSION-stable" \
	-c "$cmdline" \
	-S "$efistub_path" \
	-o /boot/uki.efi \
	/boot/vmlinuz-stable $microcode "$tmpdir"/initramfs

# .pcrsig tpm-tools PCR11
# to keep the LUKS key used too encrypt root partition
# /boot/keys/priv /boot/keys/pub (only readable by root)

# cp /boot/uki /boot/efi/boot/boot${MARCH}.efi
EOF
chmod +x "$new_root"/etc/kernel-hooks.d/uki.hook

apk_new add linux-stable
