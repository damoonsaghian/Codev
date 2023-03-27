set -e

. "$(dirname "$0")/utils.sh"

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

echo -n '[Match]
Name=en*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
' > /etc/systemd/network/20-ethernet.network
echo -n '[Match]
Name=wl*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600
' > /etc/systemd/network/20-wireless.network

systemctl enable systemd-networkd
rm -f /etc/network/interfaces

# remove these "important" packages:
apt-mark auto ifupdown isc-dhcp-client isc-dhcp-common iputils-ping nftables \
	gpgv apt-utils debconf-i18n sensible-utils procps rsyslog logrotate cron dmidecode \
	tasksel-data less nano vim-common vim-tiny whiptail e2fsprogs
apt-get --purge --yes autoremove
apt-get --yes autoclean

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /etc/apt/apt.conf.d/99_norecommends

# upgrade to sid

# install required firmwares when a new hardware is added
# https://salsa.debian.org/debian/isenkram
echo -n '#!/bin/sh
' > /usr/local/bin/install-firmware
chmod +x /usr/local/bin/install-firmware
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/install-firmware %k"' >
	/etc/udev/rules.d/80-install-firmware.rules

apt-get install --yes pkexec systemd-timesyncd dbus-user-session pipewire-audio

. "$(dirname "$0")/install-su.sh"

. "$(dirname "$0")/install-system.sh"

apt-get --yes install dosfstools exfatprogs btrfs-progs fdisk
cp "$(dirname "$0")/sd" /usr/local/bin/
chmod +x /usr/local/bin/sd
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="codev.sd.sd">
		<description>sudo</description>
		<message>sudo</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sd</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/codev.sd.policy

echo -n 'unset HISTFILE
PS1="\e[7m\u@\h\e[0m:\e[7m\w\e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

apt-get --yes install sway swayidle swaylock xwayland fuzzel foot

echo -n '# run sway (if this script is not called by a display manager, and this is the first tty)
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

cp /mnt/codev/alpine/{sway.conf,sway-status.py} /usr/local/share/

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

apt-get --yes install codev || {
	apt-get --yes install gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
		gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
		libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
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
