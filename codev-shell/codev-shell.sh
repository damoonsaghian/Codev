#!/usr/bin/env sh
script_dir="$(dirname "$(realpath "$0")")"

[ -f /etc/profile ] && . /etc/profile
for profile_script in /usr/share/profile/*.sh; do
	[ -r "$profile_script" ] && . "$profile_script"
done

export TZ="/var/lib/netman/tz"
export LANG="en_US.UTF-8"
export MUSL_LOCPATH="/usr/share/i18n/locales/musl"
export SHELL="sudo clear-groups /usr/bin/bash --noprofile --norc -i \"$script_dir\"/bashrc.sh"
export PATH="/usr/local/bin:/usr/bin:/$HOME/.local/bin"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
rm -rf "$XDG_RUNTIME_DIR"
mkdir -pm 0700 "$XDG_RUNTIME_DIR"

home-services

umask 022

if [ "$(tty)" = "/dev/tty1" ] && [ "$(id -u)" != 0 ]; then
	qml6 "$script_dir"/main.qml || bash --noprofile --norc -i "$script_dir"/bash_profile.sh
else
	bash --noprofile --norc -i "$script_dir"/bash_profile.sh
fi
