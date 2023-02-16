set -e

. "$(dirname "$0")/utils.sh"

# s6-rc inhibit shutdown
# https://packages.debian.org/sid/molly-guard
# https://blog.craftyguy.net/alpine-openrc-reboot/
# https://fitzcarraldoblog.wordpress.com/2018/01/13/running-a-shell-script-at-shutdown-only-not-at-reboot-a-comparison-between-openrc-and-systemd/

# https://www.skarnet.org/software/s6/overview.html
# https://skarnet.org/software/s6-rc/why.html
# https://skarnet.org/software/s6/
# https://skarnet.org/software/s6-rc/
# https://github.com/just-containers/s6-overlay
# https://skarnet.org/software/s6-linux-init/s6-linux-init-maker.html
# https://git.alpinelinux.org/aports/tree/main/alpine-baselayout/inittab
# https://git.alpinelinux.org/aports/tree/main/openrc?h=master
# eudev-openrc
# dbus-openrc
# elogind-openrc, seatd-openrc
# iwd-openrc
# ofono-openrc
# bluez-openrc
# clamav-daemon-openrc

# https://git.busybox.net/busybox/tree/
# https://git.alpinelinux.org/aports/tree/main/busybox?h=master

# ask if the user wants to install a new system, or fix an existing system
# ask for the device to repair
# repair the bootloader
# mount /dev/sdx /mnt
# apk fix --root /mnt
# live media can be used to fix a systems which is corrupted because of a powerloss during system upgrade
# for critical systems and for servers we can use a UPS
# atomic upgrade is not the right solution, instead we must use redundancy, backup and repair

# disable editing entries in Grub for security
[ -f /boot/grub/grub.cfg ] && {
	# since we will lock root, recovery entries are useless
	printf '\nGRUB_DISABLE_RECOVERY=true\nGRUB_DISABLE_OS_PROBER=true\nGRUB_TIMEOUT=0\n' >> /etc/default/grub
	# disable menu editing and other admin operations in Grub:
	cat <<-'__EOF__' > /etc/grub.d/09_user
	#! /bin/sh
	set superusers=""
	set menuentry_id_option="--unrestricted $menuentry_id_option"
	__EOF__
	chmod +x /etc/grub.d/09_user
	grub-mkconfig -o /boot/grub/grub.cfg
}

# despite using BTRFS, in-place writing is needed in two situations:
# 1, in-place first write for preallocated space, like in torrents
# we don't want to disable COW for these files
# apparently supported by BTRFS, isn't it?
# https://lore.kernel.org/linux-btrfs/20210213001649.GI32440@hungrycats.org/
# https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
# https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3
#
# 2, virtual machines and databases (eg the one used in Webkit)
# COW must be disabled for these files
# generally it's done automatically by the program itself (eg systemd-journald)
# otherwise we must do it manually: chattr +C ...
# apparently Webkit uses SQLite in WAL mode

apk add alpine-base linux-lts
[  ] && apk add intel-ucode
[  ] && apk add amd-ucode

apk add doas py3-gobject3

# https://wiki.debian.org/Hardening#Mounting_.2Fproc_with_hidepid

. "$(dirname "$0")/install-user.sh"

# https://wiki.alpinelinux.org/wiki/PipeWire
# pipewire: support mdev + libudev-zero:
# https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2398
apt-get install --no-install-recommends --yes wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
	cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

cp /comshell/alpine/utils.sh /usr/local/share/

apk add connman connman-nftables wpa_supplicant wireless-regdb ofono bluez
# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/
# https://wiki.archlinux.org/title/ConnMan
# https://github.com/liamw9534/pyconnman
# connman service files:
# https://git.alpinelinux.org/aports/tree/community/connman
ls -s /etc/init.d/connman /etc/runlevels/default

# automatic timezone using Connman:
# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/clock-api.txt
# set "TimezoneUpdates" to "auto" using the dbus api
# https://github.com/rilmodem/ofono/blob/master/doc/location-reporting-api.txt

set_timezone

echo -n '#!doas /bin/sh
read timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
' > /usr/local/bin/tzset
chmod +x /usr/local/bin/tzset
echo 'permit nolog nopass user1 cmd /bin/sh args /usr/local/bin/tzset' >> /etc/doas.conf

echo -n '#!/bin/sh
set -e
. /usr/local/share/utils.sh
choose selected_option "timezone\nconnections\npackages"
case "$selected_option" in
	timezone) set_timezone ;;
	connections) manage_connections ;;
	packages) manage_packages ;;
esac
' > /usr/local/bin/system
chmod +x /usr/local/bin/system

cp /mnt/comshell/alpine/system-connections.sh /usr/local/share/

echo -n '#!doas /bin/sh
set -e
local mode="$1" package_name="$2"
# nonvolatile cache can help to repaire a partial upgrade without internet 
[ -d /var/cache/apk ] || mkdir -p /var/cache/apk
[ -L /etc/apk/cache ] || ln -s /var/cache/apk /etc/apk/cache
case "$mode" in
	autoupdate) apk update; apk upgrade --clean-protected --prune ;;
	update) apk update; apk upgrade --clean-protected --prune ;;
	install) apk add --clean-protected -- "$package_name" ;;
	remove) apk del -r --purge -- "$package_name" ;;
esac
apk cache clean
' > /usr/local/bin/manage-packages
chmod +x /usr/local/bin/manage-packages
echo 'permit nolog nopass user1 cmd /bin/sh args /usr/local/bin/manage-packages' >> /etc/doas.conf

# cronjob for automatic update
# cronie cronie-openrc
# /usr/local/bin/system-packages autoupdate
# OnBootSec=5min
# OnUnitInactiveSec=24h
# RandomizedDelaySec=5min

# install the corresponding firmwares when new hardware is inserted into the machine
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/system-packages install-firmware %k"' >
	/etc/udev/rules.d/80-install-firmware.rules

# alpine-base eudev udev-init-scripts-openrc

# s6-rc inhibit shutdown
# https://skarnet.org/software/s6-linux-init/s6-linux-init-shutdownd.html
# https://git.skarnet.org/cgi-bin/cgit.cgi/s6-linux-init/tree/skel/rc.shutdown
# https://skarnet.org/software/s6-linux-init/
# https://pkgs.alpinelinux.org/package/edge/main/riscv64/s6-linux-init
# https://skarnet.org/software/s6-linux-init/s6-linux-init-maker.html
# s6-init-maker ->

echo -n 'PS1="\e[7m\u@\h\e[0m:\e[7m\w\e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

apk add dosfstools exfatprogs btrfs-progs sfdisk
cp /mnt/comshell/alpine/sd /usr/local/bin/
chmod +x /usr/local/bin/sd
echo 'permit nolog nopass user1 cmd /bin/sh args /usr/local/bin/sd' >> /etc/doas.conf

# https://wiki.alpinelinux.org/wiki/Sway
apk add sway swayidle swaylock xwayland fuzzel foot

echo -n '# run sway (if this script is not called by a display manager, and this is the first tty)
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

# https://codeberg.org/dnkl/fuzzel

# alternatives:
# tofi
# https://github.com/ii8/havoc

cp /mnt/comshell/alpine/{sway.conf,sway-status.py} /usr/local/share/

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
apk add font-noto font-hack
echo '#!doas /bin/sh
# add relevant noto font: font-noto-arabic, font-noto-cjk, ...
' >/usr/local/bin/install-font
chmod +x /usr/local/bin/install-font
echo 'permit nolog nopass user1 cmd /bin/sh args /usr/local/bin/install-font' >> /etc/doas.conf
mkdir -p /etc/fonts
echo -n '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
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

echo -n '[Desktop Entry]
Type=Application
Name=Terminal
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

apk add gtk4.0 gtksourceview5 webkit2gtk-5.0 poppler-glib vte3-gtk4 py3-cairo \
	libjxl libavif webp-pixbuf-loader librsvg \
	gst-plugins-good gst-plugins-ugly gst-plugin-pipewire gst-libav \
	libarchive-tools openssh-client-default attr
# gst-plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# gst-libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into gst-plugins-ugly
# , and av1(aom-libs) goes into gst-plugins-good
# libjxl and libavif are not compiled with gdk-pixbuf loaders (-DJPEGXL_ENABLE_PLUGINS -DAVIF_BUILD_GDK_PIXBUF)
cp -r /mnt/comshell/comshell-py /usr/local/share/
mkdir -p /usr/local/share/applications
echo -n '[Desktop Entry]
Type=Application
Name=Comshell
Exec=sh -c "swaymsg workspace 1:comshell; comshell || python3 /usr/local/share/comshell-py/"
StartupNotify=true
' > /usr/local/share/applications/comshell.desktop
