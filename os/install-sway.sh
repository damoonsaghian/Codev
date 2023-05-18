apt-get install --yes sway swayidle swaylock i3status fonts-fork-awesome grim wl-clipboard xwayland fuzzel foot

echo -n '# run sway (if this script is not called by a display manager, and this is the first tty)
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

# console level keybinding: when "F8" is pressed: loginctl lock-sessions

# to prevent BadUSB, when a new input device is connected lock the session
echo 'ACTION=="add", ATTR{bInterfaceClass}=="03" RUN+="loginctl lock-sessions"' >
	/etc/udev/rules.d/80-lock-new-hid.rules

cp "$(dirname "$0")"/{sway.conf,sway-status.sh} /usr/local/share/

echo -n 'general {
	output_format = "none"
	interval = 2
}
order += "cpu_usage"
order += "memory"
order += "battery all"
order += "wireless _first_"
order += "volume master"
order += "run_watch scrrec"
order += "time"
cpu_usage {
	format = "%usage"
}
memory {
	format = "%percentage_used"
}
battery all {
	format = "%status: %percentage"
	format_down = "null"
	format_percentage = "%d"
}
wireless _first_ {
	format_up = "%quality"
	format_down = "null"
	format_quality = "%d"
}
volume master {
	format = "%devicename: %volume"
}
run_watch scrrec {
	path = ".cache/screenrec-pid"
	format = "%status"
}
time {
	format = "%Y-%m-%d  %a  %p  %I:%M"
}
' > /usr/local/share/i3status.conf

echo -n '
' > /usr/local/share/fuzzel.ini

echo -n '
swaymsg workspace $1 &&
swaymsg "[con_id=__focused__] focus" ||
swaymsg exec $1
' > /usr/local/share/fuzzel-launch-app.sh

echo -n '#!/bin/sh
fuzzel --dmenu
case $$answer in
	lock) loginctl lock-session ;;
	suspend) systemctl suspend ;;
	exit) swaymsg exit ;;
	reboot) reboot ;;
	poweroff) poweroff ;;
esac' > /usr/local/bin/session-manager
chmod +x /usr/local/bin/session-manager
echo -n '[Desktop Entry]
Type=Application
Name=Session Manager
Icon=terminal
Exec=/usr/local/bin/session-manager
' > /usr/local/share/applications/session-manager.desktop

echo -n '[Desktop Entry]
Type=Application
Name=Terminal
Icon=terminal
Exec=footclient
StartupNotify=true
' > /usr/local/share/applications/terminal.desktop
echo -n '[Desktop Entry]
NoDisplay=true
' | tee /usr/local/share/applications/{foot,footclient,foot-server}.desktop

echo -n 'font=monospace:size=10.5
[scrollback]
indicator-position=none
[cursor]
blink=yes
[colors]
background=f8f8f8
foreground=2A2B32
selection-foreground=f8f8f8
selection-background=2A2B32
regular0=20201d  # black
regular1=d73737  # red
regular2=60ac39  # green
regular3=cfb017  # yellow
regular4=6684e1  # blue
regular5=b854d4  # magenta
regular6=1fad83  # cyan
regular7=fefbec  # white
bright0=7d7a68
bright1=d73737
bright2=60ac39
bright3=cfb017
bright4=6684e1
bright5=b854d4
bright6=1fad83
bright7=fefbec
' > /usr/local/share/foot.cfg

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<svg height="128px" viewBox="0 0 128 128" width="128px" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <linearGradient id="a" gradientUnits="userSpaceOnUse" x1="11.999989" x2="115.999989" y1="64" y2="64">
        <stop offset="0" stop-color="#3d3846"/>
        <stop offset="0.05" stop-color="#77767b"/>
        <stop offset="0.1" stop-color="#5e5c64"/>
        <stop offset="0.899999" stop-color="#504e56"/>
        <stop offset="0.95" stop-color="#77767b"/>
        <stop offset="1" stop-color="#3d3846"/>
    </linearGradient>
    <linearGradient id="b" gradientUnits="userSpaceOnUse" x1="12" x2="112.041023" y1="60" y2="80.988281">
        <stop offset="0" stop-color="#77767b"/>
        <stop offset="0.384443" stop-color="#9a9996"/>
        <stop offset="0.720567" stop-color="#77767b"/>
        <stop offset="1" stop-color="#68666f"/>
    </linearGradient>
    <path d="m 20 22 h 88 c 4.417969 0 8 3.582031 8 8 v 78 c 0 4.417969 -3.582031 8 -8 8 h -88 c -4.417969 0 -8 -3.582031 -8 -8 v -78 c 0 -4.417969 3.582031 -8 8 -8 z m 0 0" fill="url(#a)"/>
    <path d="m 20 12 h 88 c 4.417969 0 8 3.582031 8 8 v 80 c 0 4.417969 -3.582031 8 -8 8 h -88 c -4.417969 0 -8 -3.582031 -8 -8 v -80 c 0 -4.417969 3.582031 -8 8 -8 z m 0 0" fill="url(#b)"/>
    <path d="m 20 14 h 88 c 3.3125 0 6 2.6875 6 6 v 80 c 0 3.3125 -2.6875 6 -6 6 h -88 c -3.3125 0 -6 -2.6875 -6 -6 v -80 c 0 -3.3125 2.6875 -6 6 -6 z m 0 0" fill="#241f31"/>
    <g fill="#62c9ea">
        <path d="m 46.011719 40.886719 l -14.011719 -7.613281 v 4.726562 l 9.710938 4.628906 v 0.144532 l -9.710938 5.226562 v 4.726562 l 14.011719 -8.210937 z m 0 0"/>
        <path d="m 50 56 v 4 h 16 v -4 z m 0 0"/>
    </g>
</svg>
' > /usr/local/share/icons/hicolor/scalable/apps/terminal.svg
