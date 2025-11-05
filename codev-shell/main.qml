// https://quickshell.org/
// https://quickshell.org/about/
// https://quickshell.org/docs/v0.2.0/guide
// https://quickshell.org/docs/v0.2.0/types/
// https://git.outfoxxed.me/quickshell/quickshell
// https://git.outfoxxed.me/quickshell/quickshell-examples
// https://github.com/caelestia-dots/shell

// https://github.com/qt/qtwayland
// https://doc.qt.io/qt-6/qtwaylandcompositor-index.html
// https://gitlab.com/desktop-frameworks/wayqt/
// https://github.com/JUMO-GmbH-Co-KG/embedded-compositor
// https://github.com/lirios/shell

// https://docs.voidlinux.org/config/session-management.html
// https://git.sr.ht/~kennylevinsen/seatd

// https://doc.qt.io/qt-6/qml-qtnetwork-networkinformation.html

// https://invent.kde.org/plasma/plasma-keyboard

// apps will open in separate desktops
// extra windows will be floating with border shadow, and will be closed when unfocused

/*
lock
on statusbar replace apps with a lock icon, that shows the password prompt when clicked on
super, alt+tab, alt+space in lock mode: switch run codev lock, switch to codev workspace and close non'codev windows
password prompt closes (showing codev in lock mode) when Escape is pressed,
	or when empty password is entered, or simply when password prompt is unfocused
start in locked mode
to prevent BadUSB, lock when a new input device is connected

first time ask to set a password
store it in /var/password (only readable by the owner)

https://git.suckless.org/ubase/file/passwd.c.html
https://git.busybox.net/busybox/tree/loginutils/cryptpw.c
https://github.com/rfc1036/whois/blob/next/mkpasswd.c
login: runuser --user="$(id -nu 1000)" --supp-group="$(id -ng 1000),input,video" --login -c /usr/local/bin/shell
printf "set root password: "
while true; do
	read -rs root_password
	printf "enter password again: "
	read -rs root_password_again
	[ "$root_password" = "$root_password_again" ] && break
	echo "the entered passwords were not the same; try again"
	printf "set root password: "
done
root_password_hashed="$($root_password)"
mkdir -p "$spm_linux_dir"/var/lib/util-linux/passwd
echo "$root_password_hashed" > "$spm_linux_dir"/var/lib/util-linux/passwd
printf "set lock'screen password: "
while true; do
	read -rs lock_password
	printf "enter password again: "
	read -rs lock_password_again
	[ "$lock_password" = "$lock_password_again" ] && break
	echo "the entered passwords were not the same; try again"
	printf "set lock'screen password: "
done
lock_password_hashed=
echo "$lock_password_hashed" >> "$spm_linux_dir"/var/lib/util-linux/passwd
*/

/*
plugged in: lock after 10 min idle, turn off display after 15 min idle
battery: decrease brightness after 5 min idle, lock after 10 min idle, turn off display after 11 min idle
low battery: decrease brightness after 2 min idle, lock and turn off display after 4 min idle,
	suspend after 5 min idle
https://wiki.archlinux.org/title/Backlight
https://github.com/FedeDP/Clight/wiki/Modules#wayland-support
https://quickshell.org/docs/v0.1.0/types/Quickshell.Widgets/WrapperItem/
https://doc.qt.io/qt-6/qml-qtquick-effects-multieffect.html
*/

// keybinding to show the launcher
// release Super_L or Super_R
// Alt+space

// keybinding to switch between open apps
// Super+space
// Alt+Tab

// keybinding to close window
// Super+Backspace
// Super+Escape
// Alt+Backspace
// Alt+Escape

// after 600 seconds idle: lock, turn screen off
// dim screen in several steps before turning screen off

// screenshot and screencast
// https://github.com/ammen99/wf-recorder
// https://gitlab.freedesktop.org/emersion/grim

// hide cursor after 8 seconds, and when typing begins

/*
https://wiki.archlinux.org/title/Power_management
battery
power profiles (latency config) https://docs.kernel.org/power/pm_qos_interface.html
	https://github.com/linrunner/TLP
https://github.com/Hummer12007/brightnessctl
*/

// on'screen keyboard
// https://github.com/qt/qtvirtualkeyboard

// voice control
