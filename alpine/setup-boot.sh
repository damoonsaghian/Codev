case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && apk_new add amd-ucode
	[ "$cpu_vendor_id" = GenuineIntel ] && apk_new add intel-ucode
;;
esac

apk_new add systemd-boot cryptsetup tpm2-tools kernel-hooks mkinitfs

printf "title	Alpine Linux
linux	/efi/boot/vmlinuz
" > "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/amd-ucode.img ] && echo "initrd	/efi/boot/amd-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/intel-ucode.img ] && echo "initrd	/efi/boot/intel-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
printf "initrd	/efi/boot/initramfs
options cryptkey=EXEC=/usr/local/bin/tpm-getkey cryptroot=UUID=$cryptroot_uuid cryptdm=rootfs
options	root=/dev/mapper/rootfs rootflags=subvol=root,rw,noatime rootfstype=btrfs
options modules=sd-mod,usb-storage,btrfs,$modules quiet
" >> "$new_root"/boot/loader/entries/alpine.conf

printf 'default alpine.conf
timeout 0
auto-entries no
' > "$new_root"/boot/loader/loader.conf

cp "$script_dir/../codev-util/tpm-get-luks-key.sh" "$new_root"/usr/local/bin/tpm-getkey
chmod +x "$new_root"/usr/local/bin/tpm-getkey
echo '/usr/bin/tpm2_nvread
/usr/local/bin/tpm-getkey
' > "$new_root"/usr/local/share/mkinitfs/features/tpm.files

# initfs_features
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
echo "features=\"$initfs_features cryptsetup tpm\"
disable_trigger=yes
" > "$new_root"/etc/mkinitfs/mkinitfs.conf

cp "$script_dir/../codev-util/update-boot.sh" "$new_root"/etc/kernel-hooks.d/update-boot.hook
chmod +x "$new_root"/etc/kernel-hooks.d/update-boot.hook

# regenerate tpm policy, when systemd-boot or ucodes are updated
# apk hook after commit:
# [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] || [ -f /boot/*-ucode.img] && /etc/kernel-hooks.d/update-boot.hook

apk_new add linux-stable
