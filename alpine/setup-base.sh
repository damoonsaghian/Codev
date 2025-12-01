apk_new add alpine-base musl-locales setpriv btrfs-progs \
	acpid zzz eudev eudev-netifnames dbus doas-sudo-shim bash bash-completion \
	pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-spa-bluez bluez rtkit

rc_new add seedrng boot

rc_new delete hwdrivers sysinit
rc_new delete mdev sysinit
rc_new delete mdevd-init sysinit
rc_new delete mdevd sysinit
rc_new add udev sysinit
rc_new add udev-trigger sysinit
rc_new add udev-settle sysinit
rc_new add udev-postmount

rc_new add acpid
rc_new add cgroups
rc_new add dbus
rc_new add bluetooth

# to prevent BadUSB: input-gaurd service
# only the keyboard giving password is allowed in the session

# eudev rule that for all devices in /dev/dri (excluding render devices that are used for computing),
# set the group to "input" (instead of "video")
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/15409
# https://manned.org/man/udev
# https://www.reactivated.net/writing_udev_rules.html
echo 'SUBSYSTEM=="drm", KERNEL!="renderD*", GROUP="input"' > /etc/udev/rules.d/90-dri-card.rules

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
cat /home/.config/rc-services | while read service; do
	setpriv --reuid=1000 --regid=1000 --groups=plugdev,audio,video,rtkit rc-service --user "$service" restart
done
setpriv --reuid=1000 --regid=1000 --groups=plugdev,audio,video,input --inh-caps=-all codev-shell
' > /usr/local/bin/login
chmod +x /usr/local/bin/login

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

chown 1000:1000 /home
chmod 700 /home

touch /home/.config/rc-services
chown 1000:1000 /home/.config/rc-services
echo "dbus\npipewire\nwireplumber" >> /home/.config/rc-services

# doas rules:
# , nopass if id is 1000:1:2 and target is 1000
# , if id is 1000:1:2 ask for passwd

# set root password
# chroot /mnt passwd
