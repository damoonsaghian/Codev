apk_new systemd-boot mkinitfs btrfs-progs cryptsetup tpm2-tools kernel-hooks

bootconf_initrd="initrd	/efi/boot/initramfs"
case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] &&
		apk_new amd-ucode &&
		bootconf_initrd="initrd	/efi/boot/amd-ucode.img\n$bootconf_initrd"
	[ "$cpu_vendor_id" = GenuineIntel ] &&
		apk_new intel-ucode &&
		bootconf_initrd="initrd	/efi/boot/intel-ucode.img\n$bootconf_initrd"
;;
esac

modules="nvme,sd-mod,usb-storage,btrfs"
[ -e /sys/module/vmd ] && modules="$modules,vmd"

mkdir -p "$new_root"/boot/loader/entries
printf "title	Alpine Linux
linux	/efi/boot/vmlinuz
$bootconf_initrd
options cryptkey=EXEC=/usr/local/bin/tpm-getkey cryptroot=UUID=$cryptroot_uuid cryptdm=rootfs
options	root=/dev/mapper/rootfs rootflags=subvol=root,rw,noatime rootfstype=btrfs modules=$modules quiet
" > "$new_root"/boot/loader/entries/alpine.conf

printf 'default alpine.conf
timeout 0
auto-entries no
' > "$new_root"/boot/loader/loader.conf

cp "$script_dir/../codev-util/tpm-get-key.sh" "$new_root"/usr/local/bin/tpm-getkey
chmod +x "$new_root"/usr/local/bin/tpm-getkey
echo '/usr/bin/tpm2_nvread
/usr/local/bin/tpm-getkey
' > "$new_root"/usr/local/share/mkinitfs/features/tpm.files

initfs_features="ata base nvme scsi usb mmc virtio btrfs cryptsetup tpm"
[ "$(uname -m)" = "aarch64" ] && initfs_features="$initfs_features phy"
echo "features=\"$initfs_features\"
disable_trigger=yes
" > "$new_root"/etc/mkinitfs/mkinitfs.conf

# update boot partition and regenerate tpm policy, when kernel is updated
cp "$script_dir/../codev-util/update-boot.sh" "$new_root"/etc/kernel-hooks.d/update-boot.hook
chmod +x "$new_root"/etc/kernel-hooks.d/update-boot.hook

# update boot partition and regenerate tpm policy, when systemd-boot or ucodes are updated
printf '#!/usr/bin/env sh
if [ "$1" = "post-commit" ]; then
	[ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] || [ -f /boot/*-ucode.img] &&
	/etc/kernel-hooks.d/update-boot.hook
fi
' > "$new_root"/etc/apk/commit_hooks.d/update-boot.hook
chmod +x "$new_root"/etc/apk/commit_hooks.d/update-boot.hook

apk_new linux-stable
