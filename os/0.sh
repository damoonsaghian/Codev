set -e

command -v fzy || apt-get --yes install fzy

answer="$(printf "install a new system\nrepair an existing system" | fzy)"

umount --recursive --quiet /mnt || true

[ "$answer" = "repair an existing system" ] && {
	echo "select the device containing the system:"
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
	
	echo; echo -n "the system on \"$target_device\" repaired successfully; press a key to reboot"
	answer="$(printf "no\nyes" | fzy)"
	[ "$answer" = yes ] || reboot
	exit
}

arch="$(dpkg --print-architecture)"
case "$arch" in
s390x|mipsel|mips64el) echo "arichitecture \"$arch\" is not supported"; exit ;;
esac

echo "select a device:"
target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | fzy | cut -d " " -f 1)"
echo "WARNING! all the data on \"$target_device\" will be erase; do you want to continue?"
answer="$(printf "no\nyes" | fzy)"
[ "$answer" = yes ] || exit

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
		first_part_type="41,*"
		first_part_size="1M"
		part_label=dos
		;;
	*)
		first_part_type="linux,*"
		first_part_size="512M"
		part_label=dos
		;;
	esac
fi
command -v sfdisk || apt-get --yes install fdisk
sfdisk --quiet --wipe always --label $part_label "/dev/$target_device" <<__EOF__
1M,$first_part_size,$first_part_type
,,linux
__EOF__

# format and mount partitions
mkfs.btrfs "/dev/${target_device}2"
mount "/dev/${target_device}2" /mnt
if [ -d /sys/firmware/efi ]; then
	mkfs.fat -F 32 "/dev/${target_device}1"
	mkdir -p /mnt/boot/efi
	mount "/dev/${target_device}1" /mnt/boot/efi
else
	case "$arch" in
	amd64|i386) ;;
	ppc64el) ;;
	*)
		mkfs.ext2 "/dev/${target_device}1"
		mkdir /mnt/boot
		mount "/dev/${target_device}1" /mnt/boot
		;;
	esac
fi

command -v debootstrap || apt-get --yes install debootstrap
debootstrap --variant=minbase --include="init,udev,netbase,ca-certificates,usr-is-merged" \
	--components=main,contrib,non-free-firmware stable /mnt
# "usr-is-merged" is installed to avoid installing "usrmerge" (as a dependency for init-system-helpers)

mount --bind "$(dirname "$0")" /mnt/mnt

apt-get --yes install arch-install-scripts
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt sh /mnt/install.sh

echo; echo -n "installation completed successfully; press a key to reboot"
answer="$(printf "no\nyes" | fzy)"
[ "$answer" = yes ] || reboot
