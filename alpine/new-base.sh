apk_new alpine-base eudev eudev-netifnames bluez earlyoom acpid zzz dcron dbus musl-locales \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware

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

rc_new udev sysinit
rc_new udev-trigger sysinit
rc_new udev-settle sysinit
rc_new udev-postmount

# to prevent BadUSB: input-gaurd service
# only the keyboard giving password is allowed in the session

rc_new bluetooth
rc_new earlyoom
rc_new acpid

rc_new dcron
cat <<-EOF > "$new_root"/etc/cron.d/crontab
# min	hour	day		month	weekday	command
*/15	*		*		*		*		run-parts /etc/cron.d/periodic/15min
@hourly			ID=periodic.hourly		run-parts /etc/cron.d/periodic/hourly
@daily			ID=periodic.daily		run-parts /etc/cron.d/periodic/daily
@weekly			ID=periodic.weekly		run-parts /etc/cron.d/periodic/weekly
@monthly		ID=periodic.monthly		run-parts /etc/cron.d/periodic/monthly
EOF

# apk-autoupdate
printf '#!/usr/bin/env sh
metered_connection() {
	#nmcli --terse --fields GENERAL.METERED dev show | grep --quiet "yes"
	#dbus: org.freedesktop.NetworkManager Metered
}
metered_connection && exit 0
# if plugged
# inhibit suspend/shutdown when an upgrade is in progress
# if during autoupdate an error occures: echo error > /var/cache/autoupdate-status

# fwupd
# just check, if available download and show notification in status bar
' > "$new_root"/usr/local/bin/autoupdate
chmod +x "$new_root"/usr/local/bin/autoupdate
# service timer: 5min after boot, every 24h
ln --symbolic --relative "$new_root"/usr/local/bin/autoupdate "$new_root"/etc/cron.d/periodic/daily/

echo; echo "set root password (can be the same one entered before, to encrypt the root partition)"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

rmdir "$new_root"/home
chroot "$new_root" adduser --empty-password --home /home --shell /usr/local/bin/codev-shell home

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd home; do
	echo "please retry"
done

sed -i 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' "$new_root"/etc/inittab
sed -i 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' "$new_root"/etc/inittab

printf '#!/usr/bin/env sh
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304
exec login -f home
' > "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/bin/autologin

rc_new dbus
rc_new --user dbus
rc_new --user pipewire
rc_new --user wireplumber
