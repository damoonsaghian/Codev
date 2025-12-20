apk_new alpine-base eudev eudev-netifnames earlyoom acpid zzz bluez \
	networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq \
	dcron chrony musl-locales dbus \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware \
	

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

rc_new earlyoom
rc_new acpid
rc_new bluetooth
rc_new networkmanager
rc_new networkmanager-dispatcher

rc_new dcron
cat <<-EOF > "$new_root"/etc/cron.d/crontab
# min	hour	day		month	weekday	command
*/15	*		*		*		*		run-parts /etc/cron.d/periodic/15min
@hourly			ID=periodic.hourly		run-parts /etc/cron.d/periodic/hourly
@daily			ID=periodic.daily		run-parts /etc/cron.d/periodic/daily
@weekly			ID=periodic.weekly		run-parts /etc/cron.d/periodic/weekly
@monthly		ID=periodic.monthly		run-parts /etc/cron.d/periodic/monthly
EOF

ln -s /usr/local/share/codev-util/timesync.sh "$new_root"/etc/cron.d/periodic/daily/
chmod +x "$new_root"/usr/local/share/codev-util/timesync.sh

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

rc_new dbus
rc_new --nu dbus
rc_new --nu pipewire
rc_new --nu wireplumber
