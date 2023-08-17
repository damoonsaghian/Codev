set -e

arch="$(dpkg --print-architecture)"

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /etc/apt/apt.conf.d/99_norecommends

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
apt-get -qq install systemd-resolved systemd-timesyncd

apt-get install dosfstools exfatprogs btrfs-progs udisks2 eject
# allow udisks2 to mount all devices except when it's an EFI partition
echo -n 'polkit.addRule(function(action, subject) {
	function isNotEfiPartition(devicePath) {
		var partitionType = polkit.spawn(["lsblk", "--noheadings", "-o", "PARTTYPENAME", devicePath]);
		if (partitionType.indexOf("EFI System") === -1) return true;
	}
	if (subject.local && subject.active &&
		action.id === "org.freedesktop.udisks2.filesystem-mount-system" &&
		isNotEfiPartition(action.lookup("device"))
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-udisks.rules

apt-get -qq install pipewire-audio pipewire-v4l2
mkdir -p /etc/wireplumber/main.lua.d
echo 'device_defaults.properties = {
	["default-volume"] = 1.0,
	["default-input-volume"] = 1.0,
}' > /etc/wireplumber/main.lua.d/51-default-volume.lua

echo 'LANG=C.UTF-8' > /etc/default/locale

this_directory="$(dirname "$0")"

. "$this_directory/install-system.sh"

. "$this_directory/install-user.sh"

first_user="$(id -un 1000)"

apt-get install gnunet
usermod -aG gnunet "$first_user"
su -c "touch \"/home/$first_user/.config/gnunet.conf\"" "$first_user"
echo -n '[ats]
WLAN_QUOTA_IN = unlimited
WLAN_QUOTA_OUT = unlimited
WAN_QUOTA_IN = unlimited
WAN_QUOTA_OUT = unlimited
' >> "/home/$first_user/.config/gnunet.conf"

apt-get -qq install sway swayidle xwayland hicolor-icon-theme
# this way, Sway's config can't be changed by a normal user
# thus, swayidle can't be disabled by a normal user (see sway.conf)
echo -n '# run sway (if this script is not called by a display manager, and this is the first tty)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh
cp "$this_directory/sway.conf" /usr/local/share/

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

apt-get -qq install sakura
cat <<__EOF__ > "/home/$first_user/.config/sakura/sakura.conf"
[sakura]
colorset1_fore=rgb(238,238,238)
colorset1_back=rgb(34,34,34)
colorset1_curs=rgb(238,238,238)
palette=4
font=Monospace 10.5
scrollbar=false
show_tab_bar=multiple
closebutton=false
copy_on_select=true
add_tab_accelerator=4
del_tab_accelerator=4
switch_tab_accelerator=4
copy_accelerator=4
open_url_accelerator=4
search_accelerator=4
prev_tab_key=Page_Up
next_tab_key=Page_Down
copy_key=Y
__EOF__

apt-get install emacs libarchive-tools mpv luakit \
	libjxl-gdk-pixbuf libavif-gdk-pixbuf webp-pixbuf-loader gstreamer1.0-plugins-ugly gstreamer1.0-libav
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good
mkdir -p /usr/local/share/comacs
cp -r "$this_directory/../comacs" "/usr/local/share/comacs/"
