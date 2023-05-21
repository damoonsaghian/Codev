# make sure that initramfs (of the installation system) is portable across differnt hardwares
[ -f /etc/initramfs-tools/conf.d/portable-initramfs ] || {
	echo 'MODULES=most' > /etc/initramfs-tools/conf.d/portable-initramfs
	update-initramfs -u
}

echo -n 'deb https://deb.debian.org/debian unstable main contrib non-free-firmware
deb-src https://deb.debian.org/debian unstable main contrib non-free-firmware
' > /etc/apt/sources.list
apt-get update

# install all firmwares necessary for the installation process (cpu microcodes, gpu, wifi and ethernet)
# https://salsa.debian.org/images-team/debian-cd/-/blob/master/tools/generate_firmware_task
# https://salsa.debian.org/images-team/debian-cd/-/blob/master/tools/generate_firmware_patterns
# non'free: firmware-{atheros,bnx2,bnx2x,brcm80211,cavium,ipw2x00,iwlwifi,libertas,myricom,realtek,ti-connectivity}
# non'free: amd64-microcode intel-microcode atmel-firmware firmware-zd1211
# free: firmware-ath9k-htc
apt-get install --yes firmware-linux

# disable ifupdown, and activate systemd-networkd
[ -f /etc/systemd/resolved.conf ] || apt-get install --yes systemd-resolved
rm -f /etc/network/interfaces
systemctl enable systemd-networkd
systemctl start systemd-networkd
[ -f /usr/bin/iwctl ] || apt-get install --yes iwd
# ask for network configuration (if it's not a simple DHCP ethernet connection)

# install sway, a terminal emulator, and a web browser (if not installed)
# having a web browser in a rescue system can be useful

# ask if user wants to upgrade the installation system
# apt-get dist-upgrade --yes

# ask if the user wants to install a new system, or repair an existing system
# ask for the device to repaire
# mount /dev/sdx /mnt
# mount other system directories
# try to chroot and run:
# apt-get dist-upgrade || apt-get dist-upgrade --no-download
# if it failed, then:
# apt-get dist-upgrade -o RootDir=/mnt || apt-get dist-upgrade -o RootDir=/mnt --no-download
# search for required firmwares, and install them

# repaired successfully, reboot?