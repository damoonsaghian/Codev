set -e

# configure and rewrite the initramfs, to make it portable across differnt hardwares

# ask for the device to install the system on it
# create partitions and format it with BTRFS
# mount the formated partitions in "/mnt"

<<__
despite using BTRFS, in'place writing is needed in two situations:
1, in'place first write for preallocated space, like in torrents
	we don't want to disable COW for these files
	apparently supported by BTRFS, isn't it?
	https://lore.kernel.org/linux-btrfs/20210213001649.GI32440@hungrycats.org/
	https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
	https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3
2, virtual machines and databases
	COW must be disabled for these files
	generally it's done automatically by the program itself (eg systemd-journald)
	otherwise we must do it manually: chattr +C ...
	apparently Webkit uses SQLite in WAL mode
__

# debootstrap

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /mnt/etc/apt/apt.conf.d/99_norecommends

# upgrade to sid
echo -n 'deb https://deb.debian.org/debian unstable main contrib non-free
deb-src https://deb.debian.org/debian unstable main contrib non-free
' > /etc/apt/sources.list
apt-get update
apt-get dist-upgrade --yes

# lock Grub for security
# since recovery mode in Debian requires root password,
# there is no need to disable generation of recovery mode menu entries
# we just have to disable menu editing and other admin operations in Grub:
[ -f /boot/grub/grub.cfg ] &&
	printf 'set superusers=""\nset timeout=0\n' > /boot/grub/custom.cfg

# to have faster boot in EFI systems, replace grub with systemd-bootd
[ -d /boot/efi ] && {
	apt-get install --yes systemd-boot
	mkdir -p /boot/efi/loader
	printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
	
	apt-get purge --yes --ignore-missing grub-efi grub-common \
		grub-efi-amd64 grub-efi-ia32 grub-efi-arm64 grub-efi-arm shim-signed
	apt-get autoremove --purge --yes
}

# install required firmwares when a new hardware is added
# https://salsa.debian.org/debian/isenkram
echo -n '#!/bin/sh
' > /usr/local/bin/install-firmware
chmod +x /usr/local/bin/install-firmware
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/install-firmware %k"' >
	/etc/udev/rules.d/80-install-firmware.rules

. "$(dirname "$0")/install-network.sh"

apt-get install --yes pipewire-audio systemd-timesyncd dbus-user-session pkexec

. "$(dirname "$0")/install-sudo.sh"

. "$(dirname "$0")/install-system.sh"

echo -n 'unset HISTFILE
export PS1="\e[7m \u@\h \e[0m \e[7m \w \e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

apt-get install --yes sway swayidle swaylock xwayland fuzzel foot

echo -n '# run sway (if this script is not called by a display manager, and this is the first tty)
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

cp /mnt/codev/alpine/{sway.conf,sway-status.py} /usr/local/share/

# when "F8" is pressed: loginctl lock-sessions

# to prevent BadUSB, when a new input device is connected lock the session
echo 'ACTION=="add", ATTR{bInterfaceClass}=="03" RUN+="loginctl lock-sessions"' >
	/etc/udev/rules.d/80-lock-new-hid.rules

# https://codeberg.org/dnkl/fuzzel
# alternatives:
# tofi
# https://github.com/ii8/havoc

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
apt-get install --yes fonts-noto-core fonts-hack
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

apt-get install --yes codev || {
	apt-get install --yes gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
		gir1.2-udisks-2.0 dosfstools exfatprogs btrfs-progs gvfs \
		gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
		libgtk-4-media-gstreamer gstreamer1.0-{plugins-good,plugins-ugly,libav} \
		libavif-gdk-pixbuf heif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
		python3-gi python3-gi-cairo ca-certificates libarchive gnunet
	
	# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
	# libav is needed till
	# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
	# , and av1(aom-libs) goes into plugins-good
	
	# libjxl is compiled with gdk-pixbuf loader disabled, until skcms enters Debian
	
	mkdir -p /usr/local/share/codev
	cp -r /mnt/codev/src.py/* /usr/local/share/codev/
}

first_user="$(id -un 1000)"
usermod -aG gnunet "$first_user"
su -c "touch \"/home/$first_user/.config/gnunet.conf\"" "$first_user"
echo -n '[ats]
WLAN_QUOTA_IN = unlimited
WLAN_QUOTA_OUT = unlimited
WAN_QUOTA_IN = unlimited
WAN_QUOTA_OUT = unlimited
' >> "/home/$first_user/.config/gnunet.conf"

mkdir -p /usr/local/share/applications
echo -n '[Desktop Entry]
Type=Application
Name=Codev
Exec=sh -c "swaymsg workspace 1:codev; codev || python3 /usr/local/share/codev/"
StartupNotify=true
' > /usr/local/share/applications/codev.desktop

apt-get autoclean --yes

printf "installation completed successfully; reboot the system? (Y/n)"
read -r answer
[ "$answer" = n ] || reboot