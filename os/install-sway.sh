apt-get --yes install sway swayidle swaylock i3status fonts-fork-awesome grim wl-clipboard xwayland fuzzel foot

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

cp /mnt/{sway.conf,sway-status.sh} /usr/local/share/

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

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don’t have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# "https://input.djr.com/"
apt-get --yes install fonts-noto-core fonts-hack
mkdir -p /etc/fonts
echo -n '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
	<selectfont>
		<rejectfont>
			<pattern><patelt name="family"><string>NotoNastaliqUrdu</string></patelt></pattern>
			<pattern><patelt name="family"><string>NotoKufiArabic</string></patelt></pattern>
			<pattern><patelt name="family"><string>NotoNaskhArabic</string></patelt></pattern>
		</rejectfont>
	</selectfont>
	<alias>
		<family>serif</family>
		<prefer><family>NotoSerif</family></prefer>
	</alias>
	<alias>
		<family>sans</family>
		<prefer><family>NotoSans</family></prefer>
	</alias>
	<alias>
		<family>monospace</family>
		<prefer><family>Hack</family></prefer>
	</alias>
</fontconfig>
' > /etc/fonts/local.conf

#= fuzzel
echo -n 'font=sans
terminal=foot
launch-prefix=sh /usr/local/share/fuzzel-launch-app.sh
[colors]
background=222222dd
text=ffffffff
match=ffffffff
selection=4285F4dd
selection-text=ffffffff
selection-match=ffffffff
border=222222ff
[key-bindings]
cancel=Escape Control+q
' > /usr/local/share/fuzzel.ini

echo -n 'swaymsg workspace "$1"
swaymsg mark --add FOCUSED
if swaymsg "[con_mark=\"$1\"] focus"; then
	swaymsg "[workspace=__focused__ con_mark=FOCUSED] focus; unmark FOCUSED"
else
	swaymsg "unmark FOCUSED; \
		[workspace=__focused__] move workspace TMP; \
		workspace \"$1\"; \
		exec \"$1\"; \
		[workspace=TMP] move workspace current"
fi
' > /usr/local/share/fuzzel-launch-app.sh

#= session manager
echo -n '#!/bin/sh
printf "lock\nsuspend\nexit\nreboot\npoweroff" |
fuzzel --dmenu --config=/usr/local/share/fuzzel.ini | {
	read answer
	case $answer in
		lock) loginctl lock-session ;;
		suspend) systemctl suspend ;;
		exit) swaymsg exit ;;
		reboot) reboot ;;
		poweroff) poweroff ;;
	esac
}
' > /usr/local/bin/session-manager
chmod +x /usr/local/bin/session-manager

echo -n '[Desktop Entry]
Type=Application
Name=Session Manager
Icon=session-manager
Exec=/usr/local/bin/session-manager
' > /usr/local/share/applications/session-manager.desktop

mkdir -p /usr/local/share/icons/hicolor/scalable/apps
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" >
	<path d="M0 0h24v24H0z" fill="none" stroke="none"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="12" r="9"/>
</svg>
' > /usr/local/share/icons/hicolor/scalable/apps/session-manager.svg

#= foot
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
[key-bindings]
scrollback-up-page = Page_Up
scrollback-down-page = Page_Down
clipboard-copy = Control+c XF86Copy
clipboard-paste = Control+v XF86Paste
spawn-terminal = Control+n
search-start = Control+f
[search-bindings]
cancel = Escape
commit = none
find-next = Return
find-prev = Shift+Return
extend-to-next-whitespace = Shift+space
[text-bindings]
# make escape to act like ctrl+c
\x03 = Escape
[colors]
background=222222
foreground=ffffff
regular0=403E41
regular1=FF6188
regular2=A9DC76
regular3=FFD866
regular4=FC9867
regular5=AB9DF2
regular6=78DCE8
regular7=FCFCFA
bright0=727072
bright1=FF6188
bright2=A9DC76
bright3=FFD866
bright4=FC9867
bright5=AB9DF2
bright6=78DCE8
bright7=FCFCFA
selection-background=555555
selection-foreground=eeeeee
' > /usr/local/share/foot.ini

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<svg height="128px" viewBox="0 0 128 128" width="128px">
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
