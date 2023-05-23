set -e

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /etc/apt/apt.conf.d/99_norecommends
echo -n 'deb https://deb.debian.org/debian unstable main contrib non-free-firmware
deb-src https://deb.debian.org/debian unstable main contrib non-free-firmware
' > /etc/apt/sources.list
apt-get update

[ -d /sys/firmware/efi ] || {
	if [ "$arch" = s390x ]; then
		apt-get install --yes 

# [ "$arch" = s390x ] && 

# lock Grub for security
# since recovery mode in Debian requires root password,
# there is no need to disable generation of recovery mode menu entries
# we just have to disable menu editing and other admin operations in Grub:
[ -f /boot/grub/grub.cfg ] &&
	printf 'set superusers=""\nset timeout=0\n' > /boot/grub/custom.cfg

# EFI systems: systemd-bootd
[] && {
	apt-get install --yes systemd-boot
	mkdir -p /boot/efi/loader
	printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
}

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
apt-get install -yes systemd-resolved
# https://fedoramagazine.org/systemd-resolved-introduction-to-split-dns/
# https://blogs.gnome.org/mcatanzaro/2020/12/17/understanding-systemd-resolved-split-dns-and-vpn-configuration/

apt-get install --yes pipewire-audio systemd-timesyncd dbus-user-session pkexec

echo -n 'unset HISTFILE
export PS1="\e[7m \u@\h \e[0m \e[7m \w \e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

# ask for timezone (auto'detect but let the user confirm)

# ask for a root password, and a user account
while ! passwd ; do
	echo "try again"
done
echo -n "choose a username: "; read username
adduser $username netdev
while ! passwd $username; do
	echo "try again"
done

. /mnt/install-sudo.sh

. /mnt/install-system.sh

. /mnt/install-sway.sh

apt-get install --yes codev || {
	apt-get install --yes gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
		gir1.2-udisks-2.0 dosfstools exfatprogs btrfs-progs gvfs \
		gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
		libgtk-4-media-gstreamer gstreamer1.0-{plugins-good,plugins-ugly,libav} \
		libavif-gdk-pixbuf heif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
		python3-gi python3-gi-cairo wayout libarchive gnunet
	
	# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
	# libav is needed till
	# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
	# , and av1(aom-libs) goes into plugins-good
	
	# libjxl is compiled with gdk-pixbuf loader disabled, until skcms enters Debian
	
	mkdir -p /usr/local/share/codev
	cp -r /mnt/codev/src.py/* /usr/local/share/codev/
	
	cat <<-__EOF__ > /usr/local/bin/codev
	#!/bin/sh
	swaymsg workspace rename 1
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
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<path d="M16.56,5.44L15.11,6.89C16.84,7.94 18,9.83 18,12A6,6 0 0,1 12,18A6,6 0 0,1 6,12C6,9.83 7.16,7.94 8.88,6.88L7.44,5.44C5.36,6.88 4,9.28 4,12A8,8 0 0,0 12,20A8,8 0 0,0 20,12C20,9.28 18.64,6.88 16.56,5.44M13,3H11V13H13"/>
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
