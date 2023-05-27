set -e

arch="$(dpkg --print-architecture)"

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /etc/apt/apt.conf.d/99_norecommends

if [ -d /sys/firmware/efi ]; then
	apt-get --yes install systemd-boot
	mkdir -p /boot/efi/loader
	printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
else
	case "$arch" in
	amd64|i386) apt-get --yes install grub-pc ;;
	ppc64el) apt-get --yes install grub-ieee1275 ;;
	esac
	# lock Grub for security
	# recovery mode in Debian requires root password
	# so there is no need to disable generation of recovery mode menu entries
	# we just have to disable menu editing and other admin operations
	[ -f /boot/grub/grub.cfg ] &&
		printf 'set superusers=""\nset timeout=0\n' > /boot/grub/custom.cfg
fi

case "$arch" in
ppc64el) apt-get --yes install "linux-image-powerpc64le" ;;
i386) apt-get --yes install "linux-image-" ;;
armhf) apt-get --yes install "linux-image-" ;;
armel) apt-get --yes install "linux-image-" ;;
*) apt-get --yes install "linux-image-$arch" ;;
esac

# search for required firmwares, and install them
# https://salsa.debian.org/debian/isenkram
# https://salsa.debian.org/installer-team/hw-detect
#
# this script installs required firmwares when a new hardware is added
echo -n '#!/bin/sh
' > /usr/local/bin/install-firmware
chmod +x /usr/local/bin/install-firmware
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/install-firmware %k"' >
	/etc/udev/rules.d/80-install-firmware.rules

apt-get --yes install pipewire-audio dbus-user-session systemd-timesyncd

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
apt-get --yes install systemd-resolved

echo; echo -n "set username: "
read -r username
useradd --create-home --groups netdev --shell /bin/bash "$username"
while ! passwd --quiet $username; do
	echo "an error occured; please try again"
done
echo; echo "set sudo password"
while ! passwd --quiet; do
	echo "an error occured; please try again"
done
# lock root account
passwd --lock root

. /mnt/install-sudo.sh

. /mnt/install-system.sh

. /mnt/install-sway.sh

apt-get --yes install codev &> /dev/null || {
	apt-get --yes install gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
		gir1.2-udisks-2.0 dosfstools exfatprogs btrfs-progs gvfs \
		gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
		libgtk-4-media-gstreamer gstreamer1.0-{plugins-good,plugins-ugly,libav} \
		libavif-gdk-pixbuf heif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
		python3-gi python3-gi-cairo libarchive gnunet
	
	# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
	# libav is needed till
	# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
	# , and av1(aom-libs) goes into plugins-good
	
	# libjxl is compiled with gdk-pixbuf loader disabled, until skcms enters Debian
	
	mkdir -p /usr/local/share/codev
	cp -r /mnt/codev/src.py/* /usr/local/share/codev/
	
	cat <<-__EOF__ > /usr/local/bin/codev
	#!/bin/sh
	swaymsg workspace 1:codev
	python3 /usr/local/share/codev/
	__EOF__
	chmod +x /usr/local/bin/codev
	
	mkdir -p /usr/local/share/applications
	cat <<-__EOF__ > /usr/local/share/applications/codev.desktop
	[Desktop Entry]
	Type=Application
	Name=Codev
	Icon=codev
	Exec=/usr/local/bin/codev
	StartupNotify=true
	__EOF__
	
	cat <<-__EOF__ > /usr/local/share/icons/hicolor/scalable/apps/codev.svg
	<?xml version="1.0" encoding="UTF-8"?>
	<svg width="64" height="64">
		<rect style="fill:#dddddd" width="56" height="48" x="4" y="8"/>
		<rect style="fill:#aaaaaa" width="16" height="48" x="4" y="8"/>
		<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,14 H 41"/>
		<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,23 H 48"/>
		<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,32 H 48"/>
		<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,41 H 48"/>
		<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,50 H 41"/>
	</svg>
	__EOF__
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
