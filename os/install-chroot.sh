set -e

arch="$(dpkg --print-architecture)"

echo -n 'deb http://deb.debian.org/debian stable main contrib non-free-firmware
deb http://deb.debian.org/debian stable-updates main contrib non-free-firmware
deb http://deb.debian.org/debian-security stable-security main contrib non-free-firmware
' > /etc/apt/sources.list
apt-get -qq update

case "$arch" in
ppc64el) apt-get -qq install "linux-image-powerpc64le" ;;
i386)
	if grep -q '^flags.*\blm\b' /proc/cpuinfo; then
		apt-get -qq install "linux-image-686-pae"
	elif grep -q '^flags.*\bpae\b' /proc/cpuinfo; then
		apt-get -qq install "linux-image-686-pae"
	else
		apt-get -qq install "linux-image-686"
	fi ;;
armhf)
	if grep -q '^Features.*\blpae\b' /proc/cpuinfo; then
		apt-get -qq install "linux-image-armmp-lpae"
	else
		apt-get -qq install "linux-image-armmp"
	fi ;;
armel) apt-get -qq install "linux-image-marvell" ;;
*) apt-get -qq install "linux-image-$arch" ;;
esac

if [ -d /sys/firmware/efi ]; then
	echo "root=UUID=$(findmnt -n -o UUID /) ro quiet" > /etc/kernel/cmdline
	apt-get -qq install systemd-boot
	mkdir -p /boot/efi/loader
	printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
else
	case "$arch" in
	amd64|i386) apt-get -qq install grub-pc ;;
	ppc64el) apt-get -qq install grub-ieee1275 ;;
	esac
	# lock Grub for security
	# recovery mode in Debian requires root password
	# so there is no need to disable generation of recovery mode menu entries
	# we just have to disable menu editing and other admin operations
	[ -f /boot/grub/grub.cfg ] && {
		printf 'set superusers=""\nset timeout=0\n' > /boot/grub/custom.cfg
		update-grub
	}
fi

# search for required firmwares, and install them
# https://salsa.debian.org/debian/isenkram
# https://salsa.debian.org/installer-team/hw-detect
#
# for now just install all firmwares
apt-get -qq install live-task-non-free-firmware-pc
#
# this script installs required firmwares when a new hardware is added
echo -n '#!/bin/sh
' > /usr/local/bin/install-firmware
chmod +x /usr/local/bin/install-firmware
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/install-firmware %k"' > \
	/etc/udev/rules.d/80-install-firmware.rules

apt-get -qq install pipewire-audio pipewire-v4l2
mkdir -p /etc/wireplumber/main.lua.d
echo 'device_defaults.properties = {
	["default-volume"] = 1.0,
	["default-input-volume"] = 1.0,
}' > /etc/wireplumber/main.lua.d/51-default-volume.lua

echo -n '[Match]
Name=en*
Name=eth*
#Type=ether
#Name=! veth*
[Network]
DHCP=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
' > /etc/systemd/network/20-ethernet.network
echo -n '[Match]
Name=wl*
#Type=wlan
#WLANInterfaceType=station
[Network]
DHCP=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600
' > /etc/systemd/network/20-wireless.network
echo -n '[Match]
Name=ww*
#Type=wwan
[Network]
DHCP=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=700
[IPv6AcceptRA]
RouteMetric=700
' > /etc/systemd/network/20-wwan.network
# https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wwan.network
# https://wiki.archlinux.org/title/Mobile_broadband_modem
# https://github.com/systemd/systemd/issues/20370
systemctl enable systemd-networkd
apt-get -qq install systemd-resolved

apt-get -qq install iwd wireless-regdb bluez rfkill
systemctl enable iwd.service
echo '# allow rfkill for users in the netdev group
KERNEL=="rfkill", MODE="0664", GROUP="netdev"
' > /etc/udev/rules.d/80-rfkill.rules

echo; echo "setting timezone"
# guess the timezone, but let the user to confirm it
command -v wget > /dev/null 2>&1 || apt-get -qq install wget > /dev/null 2>&1 || true
geoip_tz="$(wget -q -O- 'http://ip-api.com/line/?fields=timezone')"
geoip_tz_continent="$(echo "$geoip_tz" | cut -d / -f1)"
geoip_tz_city="$(echo "$geoip_tz" | cut -d / -f2)"
tz_continent="$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5 |
	fzy -p "select a continent: " -q "$geoip_tz_continent")"
tz_city="$(ls -1 /usr/share/zoneinfo/"$tz_continent"/* | cut -d / -f6 |
	fzy -p "select a city: " -q "$geoip_tz_city")"
ln -sf "/usr/share/zoneinfo/${tz_continent}/${tz_city}" /etc/localtime

echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.timedate1.set-timezone" &&
		subject.local && subject.active
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-timezone.rules

. /mnt/os/install-upm.sh
. /mnt/os/install-user.sh

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don’t have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# "https://github.com/iaolo/iA-Fonts/tree/master/iA%20Writer%20Quattro"
# "https://input.djr.com/"
apt-get -qq install fonts-noto-core fonts-hack
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

apt-get -qq install sway swayidle xwayland python3-gi gir1.2-gtk-4.0 gnome-console
cp /mnt/os/sway.conf /mnt/os/swapps.py /usr/local/share/
# this way, Sway's config can't be changed by a normal user
# this means that, swayidle can't be disabled by a normal user (see sway.conf)
echo -n '# run sway (if this script is not called by root or a display manager, and this is the first tty)
if [ ! "$(id -u)" = 0 ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

apt-get -qq install gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
	libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libarchive-tools gvfs dosfstools exfatprogs btrfs-progs gnunet
# libjxl in Debian is old, and does not have gdk-pixbuf loader
# https://packages.debian.org/source/bookworm/jpeg-xl
#
# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good
cp /mnt/codev /usr/local/share/
