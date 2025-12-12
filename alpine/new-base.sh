apk_new add alpine-base eudev eudev-netifnames earlyoom acpid zzz dcron \
	musl-locales setpriv doas-sudo-shim dbus bluez \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware

rc_new add seedrng boot
rc_new add cgroups

rc_new add udev sysinit
rc_new add udev-trigger sysinit
rc_new add udev-settle sysinit
rc_new add udev-postmount

# to prevent BadUSB: input-gaurd service
# only the keyboard giving password is allowed in the session

rc_new add earlyoom
rc_new add acpid

rc_new add dcron
cat <<-EOF > "$new_root"/etc/cron.d/crontab
# min	hour	day		month	weekday	command
*/15	*		*		*		*		run-parts /etc/cron.d/periodic/15min
@hourly			ID=periodic.hourly		run-parts /etc/cron.d/periodic/hourly
@daily			ID=periodic.daily		run-parts /etc/cron.d/periodic/daily
@weekly			ID=periodic.weekly		run-parts /etc/cron.d/periodic/weekly
@monthly		ID=periodic.monthly		run-parts /etc/cron.d/periodic/monthly
EOF

sed -i 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/login@' /etc/inittab

printf '#!/usr/bin/env sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
export TZ="/var/lib/netman/tz"
export LANG="en_US.UTF-8"
export MUSL_LOCPATH="/usr/share/i18n/locales/musl"
export HOME="/home"
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export WAYLAND_DISPLAY="wayland-0"
rm -rf /run/user/1000
mkdir -p /run/user/1000
chown 1000:1000 /run/user/1000
chmod 700 /run/user/1000
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304
cat /home/.config/rc-services | while read service; do
	setpriv --reuid=1000 --regid=1000 --groups=plugdev,gnunet,audio,video \
		rc-service --user "$service" restart
done
setpriv --reuid=1000 --regid=1000 --groups=plugdev,gnunet,video,input \
	--inh-caps=-all+SYS_RESOURCE codev-shell
' > /usr/local/bin/login
chmod +x /usr/local/bin/login

cat <<-EOF > /etc/doas.d/shell.conf
permit nopass 1000:input as 1000
permit 1000:input
EOF

chown 1000:1000 /home
chmod 700 /home

# set root password
chroot "$new_root" passwd

mkdir -p /etc/doas.d
# using "sudo" in CodevShell does not suffer from these flaws:
# https://www.reddit.com/r/linuxquestions/comments/8mlil7/whats_the_point_of_the_sudo_password_prompt_if/
# https://security.stackexchange.com/questions/119410/why-should-one-use-sudo
# because:
# , when a user enters "sudo" in command line, it will run /usr/bin/sudo
# , reaching to terminal in CodevShell can't be manipulated by normal user
# 	app launcher -> system -> sudo <command>
# , CodevShell only allows keyboard input from real keyboard, or from the built'in on'screen keyboard
# , there is no way for normal user to replace CodevShell
# , sudo works only when called from CodevShell
# all these imply:
# , a malicious program can't steal root password (eg by faking password entry)
# , to run a command as root, physical access is necessary, because there is no other way to enter root password

rc_new add dbus
rc_new add bluetooth

touch /home/.config/rc-services
chown 1000:1000 /home/.config/rc-services
echo "dbus\npipewire\nwireplumber" >> /home/.config/rc-services
