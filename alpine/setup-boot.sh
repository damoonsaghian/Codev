case "$(cat /etc/apk/arch)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && apk_new add amd-ucode
	[ "$cpu_vendor_id" = GenuineIntel ] && apk_new add intel-ucode
;;
esac

apk_new add systemd-boot tpm2-tools kernel-hooks mkinitfs

printf "title	Alpine Linux
linux	/efi/boot/vmlinuz
" > "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/amd-ucode.img ] && echo "initrd	/efi/boot/amd-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
[ -f /boot/intel-ucode.img ] && echo "initrd	/efi/boot/intel-ucode.img" >> "$new_root"/boot/loader/entries/alpine.conf
printf "initrd	/efi/boot/initramfs
options	root=UUID=$root_uuid ro modules=sd-mod,usb-storage,btrfs,nvme quiet rootfstype=btrfs
options root=UUID=$cryptroot_uuid cryptkey=EXEC=/usr/local/bin/tpm-unseal-luks-key
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

# regenerate tpm policy, when systemd-boot or ucodes are updated
# apk hook after commit:
# [ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] || [ -f /boot/*-ucode.img] && /etc/kernel-hooks.d/pcr-policy.hook

apk_new add linux-stable
