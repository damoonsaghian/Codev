set -e

fzy -v &> /dev/null || apt-get --yes install fzy

answer="$(printf "install a new system\nrepair an existing system")"

[ "$answer" = "repair an existing system" ] && {
	echo "select the device containing the system to repair:"
	target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | fzy | cut -d " " -f 1)"
	mount "/dev/$target_device" /mnt
	# mount other system directories
	
	# try to chroot and run:
	# apt-get dist-upgrade
	# if it failed, then:
	# debootstrap --variant=minbase unstable /mnt
	# then chroot and run:
	# apt-get dist-upgrade
	
	# search for required firmwares, and install them
	
	echo; printf "the system \"$target_device\" repaired successfully; press a key to reboot"
	read -n 1 -s
	reboot
}

echo "select a device:"
target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | fzy | cut -d " " -f 1)"

arch="$(dpkg --print-architecture)"
case "$arch" in
s390x|mipsel|mips64el) echo "arichitecture \"$arch\" is not supported"; exit ;;
esac

# create partitions
if [ -d /sys/firmware/efi ]; then
	first_part_type=uefi
	first_part_size="512M"
	part_label=gpt
else
	case "$arch" in
	amd64|i386)
		first_part_type="21686148-6449-6E6F-744E-656564454649"
		first_part_size="1M"
		part_label=gpt
		;;
 	ppc64el)
		first_part_type=
		first_part_size=
		part_label=mbr
		;;
	*)
		first_part_type=
		first_part_size=
		part_label=mbr
		;;
	esac
fi
sfdisk -v &> /dev/null || apt-get --yes install fdisk
printf "1M,$first_part_size,$first_part_type\n,,linux" |
	sfdisk --quiet --wipe always --label $part_label "/dev/$target_device"

# format and mount partitions
mkfs.btrfs "/dev/${target_device}2"
mount "/dev/${target_device}2" /mnt
if [ -d /sys/firmware/efi ]; then
	mkfs.vfat "/dev/${target_device}1"
	mount "/dev/${target_device}1" /mnt/boot/efi
else
	case "$arch" in
	amd64|i386) ;;
	ppc64el) ;;
	*)
		mkfs.ext2 "/dev/${target_device}1"
		mount /dev/"$target_device"1 /mnt/boot
		;;
	esac
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
debootstrap --variant=minbase --include="$pkgs_impt,$pkgs_std,usr-is-merged,$pkgs" \
	--components=main,contrib,non-free-firmware unstable /mnt
# usr-is-merged: avoid usrmerge (a dependency of init-system-helpers) which installs perl as dependency

# https://salsa.debian.org/installer-team/debian-installer-utils/-/blob/master/chroot-setup.sh
mount --bind "$(dirname "$0")" /mnt/mnt
mount --bind /dev /mnt/dev
mount -t proc proc /mnt/proc
if [ -d /sys/firmware/efi ]; then
	mkdir -p /mnt/boot/efi
	mount "/dev/${target_device}1" /mnt/boot/efi
fi

chroot /mnt sh /mnt/install.sh

echo; printf "installation completed successfully; press a key to reboot"
read -n 1 -s
reboot
