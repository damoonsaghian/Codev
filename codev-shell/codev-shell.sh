#!/usr/bin/env sh
script_dir="$(dirname "$(realpath "$0")")"

[ -f /etc/profile ] && . /etc/profile

for profile_script in /usr/share/profile/*.sh; do
	[ -r "$profile_script" ] && . "$profile_script"
done

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

home-services

cat /home/.config/rc-services | while read service; do
	setpriv --reuid=1000 --regid=1000 --groups=plugdev,gnunet,audio,video rc-service --user "$service" restart
done
setpriv --reuid=1000 --regid=1000 --groups=plugdev,gnunet,video,input --inh-caps=-all codev-shell

export PATH="$PATH:/$HOME/.local/bin"
export PAGER=less
export SHELL="/usr/bin/bash --noprofile --norc -i \"$script_dir\"/bashrc.sh"

umask 022

cd "$HOME"

text_shell() {
	# ask:
	# , auto repair (spm update)
	# , backup
	# , copy projects
	# , shell
	bash --noprofile --norc -i "$script_dir"/bashrc.sh
}

if [ "$(tty)" = "/dev/tty1" ]; then
	qml6 "$script_dir"/main.qml || text_shell
else
	text_shell
fi
