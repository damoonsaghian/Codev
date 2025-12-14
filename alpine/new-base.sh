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

echo '#!/usr/bin/env sh
openrc -U
' > "$new_root"/usr/local/bin/home-services
chmod +x "$new_root"/usr/local/bin/home-services

rmdir "$new_root"/home
adduser --home /home --shell /usr/local/bin/codev-shell home
chroot "$new_root" passwd home

# set root password
chroot "$new_root" passwd

sed -i 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/login@' /etc/inittab

printf '#!/usr/bin/env sh
exec login -f normaluser
' > "$new_root"/usr/local/bin/login
chmod +x "$new_root"/usr/local/bin/login

cat <<-EOF > /etc/doas.d/shell.conf
permit nopass normaluser:input as normaluser
permit nopass normaluser:input /usr/bin/passwd normaluser
permit :input
EOF

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

rc_new dbus
rc_new --user dbus
rc_new bluetooth
rc_new --user pipewire
rc_new --user wireplumber
