set -e

# make sure that initramfs (of the installation system) is portable across differnt hardwares
[ -f /etc/initramfs-tools/conf.d/portable-initramfs ] || {
	echo 'MODULES=most' > /etc/initramfs-tools/conf.d/portable-initramfs
	update-initramfs -u
}

# install all firmwares (on the installation system)

# install sway, a terminal emulator, and a web browser
# having a web browser in a rescue system can be useful

# ask for confirmation for auto'detected time'zone

# disable ifupdown, and activate systemd-networkd
[ -f /etc/systemd/resolved.conf ] || apt-get install --yes systemd-resolved
rm -f /etc/network/interfaces
systemctl enable systemd-networkd
systemctl start systemd-networkd
[ -f /usr/bin/iwctl ] || apt-get install --yes iwd
# ask for network configuration (if it's not a simple DHCP ethernet connection)

# ask if the user wants to install a new system, or fix an existing system
# ask for the device to repaire
# mount /dev/sdx /mnt
# mount other system directories
# try to chroot and run:
# apt-get dist-upgrade || apt-get dist-upgrade --no-download
# if it failed, then:
# apt-get dist-upgrade -o RootDir=/mnt || apt-get dist-upgrade -o RootDir=/mnt --no-download

# ask for the device to install the system on it (if there is more than one device)
# create partitions and format them (use BTRFS for root)
# mount the formated partitions in "/mnt"

# despite using BTRFS, in'place writing is needed in two situations:
# 1, in'place first write for preallocated space, like in torrents
# 	we don't want to disable COW for these files
# 	apparently supported by BTRFS, isn't it?
# 	https://lore.kernel.org/linux-btrfs/20210213001649.GI32440@hungrycats.org/
# 	https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
# 	https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3
# 2, virtual machines and databases
# 	COW must be disabled for these files
# 	generally it's done automatically by the program itself (eg systemd-journald and PostgreSQL)
# 	otherwise we must do it manually: chattr +C ... (eg for MariaDB databases)
# 	apparently Webkit uses SQLite in WAL mode, but i'm not sure about GnuNet

pkgs_impt="init,udev,netbase"
pkgs_std="ca-certificates"
pkgs=""
debootstrap --variant=minbase --include="$pkgs_impt,$pkgs_std,usr-is-merged,$pkgs" unstable /mnt

# also install usr-is-merged, to avoid usrmerge (a dependency of init-system-helpers),
# which installs perl as dependency

mount --bind "$(dirname "$0")" /mnt/mnt
mount --bind /dev /mnt/dev
mount -t proc proc /mnt/proc
LANG=C.UTF-8 chroot /mnt /bin/bash
mount "/dev/${dev_name}1" /boot/efi

echo -n 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
' > /etc/apt/apt.conf.d/99_norecommends

# if not efi, install Grub

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

# install required firmwares when a new hardware is added
# https://salsa.debian.org/debian/isenkram
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

# ask for timezone

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

printf "installation completed successfully; reboot the system? (Y/n)"
read -r answer
[ "$answer" = n ] || reboot
