set -e

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

# autologin root

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
# debootstrap --variant=minbase unstable /mnt
# then chroot and run:
# apt-get dist-upgrade || apt-get dist-upgrade --no-download
# search for required firmwares, and install them

# repaired successfully, reboot?

fzy -v &> /dev/null || apt-get install --yes fzy
sfdisk -v &> /dev/null || apt-get install --yes fdisk

# ask for the device to install the system on it
target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | fzy | cut -d " " -f 1)"

# create partitions and format them (use BTRFS for root)
first_part_type=uefi
first_part_size="512M"
arch="$(dpkg --print-architecture)"
[ $arch = amd64 ] || [ $arch = i386 ] && [ ! -d /sys/firmware/efi ] && {
	first_part_type="21686148-6449-6E6F-744E-656564454649"
	first_part_size="1M"
}
[ "$architectur" = ppc64el ] &&
[ "$architectur" = s390x ] && { first_part_type= ; first_part_size= ; }
printf "1M,$first_part_size,$first_part_type\n,,linux" |
	sfdisk --quiet --wipe always --label gpt "/dev/$target_device"

# mount root partition, anf EFI partition (if any)
mount /dev/"$target_device"2 /mnt
if [ -d /sys/firmware/efi ]; then
	mkdir -p /mnt/boot/efi
	mount /dev/"$target_device"1 /mnt/boot/efi
fi

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
# usr-is-merged: avoid usrmerge (a dependency of init-system-helpers) which installs perl as dependency

# https://salsa.debian.org/installer-team/debian-installer-utils/-/blob/master/chroot-setup.sh
mount --bind "$(dirname "$0")" /mnt/mnt
mount --bind /dev /mnt/dev
mount -t proc proc /mnt/proc
mount "/dev/${dev_name}1" /mnt/boot/efi

chroot /mnt sh /mnt/install.sh

printf "installation completed successfully; reboot the system? (Y/n)"
read -r answer
[ "$answer" = n ] || reboot
