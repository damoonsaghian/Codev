apk_new alpine-base
rc_new devfs sysinit
rc_new dmesg sysinit
rc_new bootmisc boot
rc_new hostname boot
rc_new hwclock boot
rc_new modules boot
rc_new seedrng boot
rc_new sysctl boot
rc_new syslog boot # in busybox
rc_new cgroups
rc_new savecache shutdown
rc_new killprocs shutdown
rc_new mount-ro shutdown

apk_new eudev eudev-netifnames earlyoom acpid zzz bluez \
	networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq chrony dcron
rc_new udev sysinit
rc_new udev-trigger sysinit
rc_new udev-settle sysinit
rc_new udev-postmount
rc_new earlyoom
rc_new acpid
rc_new bluetooth
rc_new networkmanager
rc_new networkmanager-dispatcher
rc_new dcron

cp -r "$script_dir"/../codev-util "$new_root"/usr/local/share/

chmod +x "$new_root"/usr/local/share/codev-util/timesync.sh
ln -s /usr/local/share/codev-util/timesync.sh "$new_root"/usr/local/bin/timesync
echo '@daily ID=timesync timesync
@reboot timesync reboot
' > "$new_root"/etc/cron.d/timesync

mkdir -p "$new_root"/usr/local/share/spm
cp -r "$script_dir"/* "$new_root"/usr/local/share/spm/
chmod +x "$new_root"/usr/local/share/spm/spm.sh
ln -s /usr/local/share/spm/spm.sh "$new_root"/usr/local/bin/spm
echo 'permit nopass nu cmd /usr/local/bin/spm' > "$new_root"/etc/doas.d/spm.conf

chmod +x "$new_root"/usr/local/share/codev-util/spm-autoup.sh
ln -s /usr/local/share/codev-util/spm-autoup.sh "$new_root"/usr/local/bin/spm-autoup
echo '@daily ID=autoupdate spm-autoup' > "$new_root"/etc/cron.d/spm-autoup

chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey
echo '/usr/bin/tpm2_nvread
/usr/local/bin/tpm-getkey
' > "$new_root"/usr/local/share/mkinitfs/features/tpm.files

echo "disable_trigger=yes" > "$new_root"/etc/mkinitfs/mkinitfs.conf

# setup boot files and regenerate tpm policy, when systemd-boot or ucodes or kernel are updated
chmod +x "$new_root"/usr/local/share/codev-util/spm-bootup.sh
ln -s /usr/local/share/codev-util/spm-bootup.sh "$new_root"/usr/local/bin/spm-bootup
printf '#!/usr/bin/env sh
if [ "$1" = "post-commit" ]; then
	[ -f /usr/lib/systemd/boot/efi/system-boot*.efi ] || [ -f /boot/*-ucode.img ] || [ -f /boot/vmlinuz-stable ] &&
	spm-bootup
fi
' > "$new_root"/etc/apk/commit_hooks.d/spm-bootup.hook
chmod +x "$new_root"/etc/apk/commit_hooks.d/spm-bootup.hook

apk_new linux-stable systemd-boot mkinitfs btrfs-progs cryptsetup tpm2-tools
case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && apk_new amd-ucode
	[ "$cpu_vendor_id" = GenuineIntel ] && apk_new intel-ucode
;;
esac

echo; echo "set root password (can be the same one entered before, to encrypt the root partition)"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

# create a normal user
chroot "$new_root" adduser --empty-password --home /nu --shell /usr/local/bin/codev-shell nu

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done

sed -i 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' "$new_root"/etc/inittab
sed -i 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' "$new_root"/etc/inittab

printf '#!/usr/bin/env sh
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304
exec login -f nu
' > "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/bin/autologin
