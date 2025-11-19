case "$(cat /etc/apk/arch)" in
	x86*) apk_new add amd-ucode intel-ucode;;
esac
# if the installation target in not removable, find if current cpu is amd or intel, and only install that ucode

apk_new add systemd-boot tpm2-tools kernel-hooks mkinitfs

root_fs_uuid=

printf "title	Alpine Linux
linux	/efi/boot/vmlinuz
" > "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/amd-ucode.img ] && echo "initrd	/efi/boot/amd-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/intel-ucode.img ] && echo "initrd	/efi/boot/intel-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
printf "initrd	/efi/boot/initramfs
options	root=UUID=$root_fs_uuid ro modules=sd-mod,usb-storage,btrfs,nvme quiet rootfstype=btrfs
options cryptkey=EXEC=/usr/local/bin/tpm-unseal-luks-key
" >> "$new_root"/boot/loader/entries/alpine.conf

printf 'default alpine.conf
timeout 0
auto-entries no
' > "$new_root"/boot/loader/loader.conf

echo 'disable_trigger=yes' >> "$new_root"/etc/mkinitfs/mkinitfs.conf

cp "$script_dir/tpm-unseal-luks-key.sh" "$new_root"/usr/local/bin/tpm-unseal-luks-key
chmod +x "$new_root"/usr/local/bin/tpm-unseal-luks-key

cp "$script_dir/pcr-policy-hook.sh" "$new_root"/etc/kernel-hooks.d/tpm-policy.hook
chmod +x "$new_root"/etc/kernel-hooks.d/tpm-policy.hook

# regenerate pcr policy, when systemd-boot or ucodes are updated
# apk hook after commit:
# [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] || [ -f /boot/*-ucode.img] && /etc/kernel-hooks.d/pcr-policy.hook

apk_new add linux-stable
