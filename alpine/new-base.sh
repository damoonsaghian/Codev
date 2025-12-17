apk_new alpine-base eudev eudev-netifnames earlyoom acpid zzz dcron \
	musl-locales setpriv doas-sudo-shim dbus bluez \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware

rc_new seedrng boot
rc_new cgroups

rc_new udev sysinit
rc_new udev-trigger sysinit
rc_new udev-settle sysinit
rc_new udev-postmount

# to prevent BadUSB: input-gaurd service
# only the keyboard giving password is allowed in the session

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

echo; echo "set root password (can be the same one entered before, to encrypt the root partition)"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

rmdir "$new_root"/home
chroot "$new_root" adduser --empty-password --home /home --shell /usr/local/bin/codev-shell home
chroot "$new_root" adduser home input
chroot "$new_root" adduser home video
chroot "$new_root" adduser home audio

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd home; do
	echo "please retry"
done

sed -i 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' /etc/inittab
sed -i 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' /etc/inittab

printf '#!/usr/bin/env sh
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304
exec login -f home
' > "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/bin/autologin

echo '#!/usr/bin/env sh
openrc -U
' > "$new_root"/usr/local/bin/home-services
chmod +x "$new_root"/usr/local/bin/home-services

echo '#!/usr/bin/env sh
setpriv --reuid=$(id -u "$DOAS_USER") --regid=$(id -g "$DOAS_USER") --clear-groups $@
' > "$new_root"/usr/local/bin/clear-groups
chmod +x "$new_root"/usr/local/bin/clear-groups

mkdir -p /etc/doas.d
cat <<-EOF > /etc/doas.d/shell.conf
permit nopass home cmd /usr/local/bin/clear-groups
permit nopass home cmd /usr/bin/passwd home
EOF
# using "sudo" in CodevShell does not suffer from these flaws:
# https://www.reddit.com/r/linuxquestions/comments/8mlil7/whats_the_point_of_the_sudo_password_prompt_if/
# https://security.stackexchange.com/questions/119410/why-should-one-use-sudo
# because:
# , when a user enters "sudo" in command line, it will run /usr/bin/sudo
# 	this can't be manipulated by normal user
# , reaching to terminal in CodevShell: app launcher -> space
# 	this can't be manipulated by normal user
# , CodevShell only allows keyboard input from real keyboard, or from its built'in on'screen keyboard
# , though CodevShell has access to input and video devices,
# 	that privilage will be dropped (using "clear-groups") for all launched apps and commands
# , there is no way for normal user to replace CodevShell
# so a malicious program can't steal root password (eg by faking password entry)

rc_new dbus
rc_new --user dbus
rc_new bluetooth
rc_new --user pipewire
rc_new --user wireplumber
