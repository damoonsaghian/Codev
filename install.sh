set -e

arch="$(dpkg --print-architecture)"
case "$arch" in
s390x|mipsel|mips64el) echo "arichitecture \"$arch\" is not supported"; exit ;;
esac

command -v fzy > /dev/null 2>&1 || apt-get -qq install fzy || {
	echo "internet connection is required"
	exit 1
}
command -v debootstrap > /dev/null 2>&1 || apt-get -qq install debootstrap
command -v arch-chroot > /dev/null 2>&1 || apt-get -qq install arch-install-scripts

umount --recursive --quiet /mnt || true

answer="$(printf "install a new system\nrepair an existing system" | fzy -p "select an option: ")"

[ "$answer" = "repair an existing system" ] && {
	target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | 
		fzy -p "select the device containing the system: " | cut -d " " -f 1)"
	
	target_partitions="$(lsblk --list --noheadings -o PATH "/dev/$target_device")"
	target_partition1="$(echo "$target_partitions" | sed -n '2p')"
	target_partition2="$(echo "$target_partitions" | sed -n '3p')"
	
	mount "$target_partition2" /mnt
	if [ -d /sys/firmware/efi ]; then
		mkdir -p /mnt/boot/efi
		mount "$target_partition1" /mnt/boot/efi
	else
		case "$arch" in
		amd64|i386) ;;
		ppc64el) ;;
		*) mkdir /mnt/boot; mount "$target_partition1" /mnt/boot ;;
		esac
	fi
	
	arch-chroot /mnt apt-get dist-upgrade || {
		backup_dir_path="/mnt/backup$(date '+%s')"
		mkdir "$backup_dir_path"
		mv /mnt/* "$backup_dir_path/"
		debootstrap --variant=minbase --include="init,btrfs-progs,udev,netbase,ca-certificates,usr-is-merged" \
			--components=main,contrib,non-free-firmware stable /mnt
	}
	
	genfstab -U /mnt > /mnt/etc/fstab
	mount --bind "$(dirname "$0")" /mnt/mnt
	arch-chroot /mnt sh /mnt/os/install-chroot.sh
	
	echo; echo -n "the system on \"$target_device\" repaired successfully"
	answer="$(printf "no\nyes" | fzy -p "reboot the system? ")"
	[ "$answer" = yes ] && systemctl reboot
	exit
}

target_device="$(lsblk --nodep --noheadings -o NAME,SIZE,MODEL | fzy -p "select a device: " | cut -d " " -f 1)"
answer="$(printf "no\nyes" | fzy -p "WARNING! all the data on \"$target_device\" will be erased; continue? ")"
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

second_partition_type=linux
case "$arch" in
amd64) second_partition_type=4f68bce3-e8cd-4db1-96e7-fbcaf984b709 ;;
i386) second_partition_type=44479540-f297-41b2-9af7-d131d5f0458a ;;
arm64) second_partition_type=b921b045-1df0-41c3-af44-4c6f280d3fae ;;
armel|armhf) second_partition_type=69dad710-2ce4-4e3c-b16c-21a1d49abed3 ;;
ppc64el) second_partition_type=c31c45e6-3f39-412e-80fb-4809c4980599 ;;
riscv64) second_partition_type=72ec70a6-cf74-40e6-bd49-4bda08e8f224 ;;
esac

command -v sfdisk > /dev/null 2>&1 || apt-get -qq install fdisk
sfdisk --quiet --wipe always --label $part_label "/dev/$target_device" <<__EOF__
1M,$first_part_size,$first_part_type
,,$second_partition_type
__EOF__

target_partitions="$(lsblk --list --noheadings -o PATH "/dev/$target_device")"
target_partition1="$(echo "$target_partitions" | sed -n '2p')"
target_partition2="$(echo "$target_partitions" | sed -n '3p')"

# format and mount partitions
mkfs.btrfs -f --quiet "$target_partition2" > /dev/null 2>&1
mount "$target_partition2" /mnt
if [ -d /sys/firmware/efi ]; then
	mkfs.fat -F 32 "$target_partition1" > /dev/null 2>&1
	mkdir -p /mnt/boot/efi
	mount "$target_partition1" /mnt/boot/efi
else
	case "$arch" in
	amd64|i386) ;;
	ppc64el) ;;
	*)
		mkfs.ext2 "$target_partition1" > /dev/null 2>&1
		mkdir /mnt/boot
		mount "$target_partition1" /mnt/boot
		;;
	esac
fi

debootstrap --variant=minbase --include="init,btrfs-progs,udev,netbase,ca-certificates,usr-is-merged" \
	--components=main,contrib,non-free-firmware stable /mnt
# "usr-is-merged" is installed to avoid installing "usrmerge" (as a dependency for init-system-helpers)

genfstab -U /mnt > /mnt/etc/fstab
mount --bind "$(dirname "$0")" /mnt/mnt
arch-chroot /mnt sh /mnt/os/install-chroot.sh

# arch-chroot copies /media into the new system; it must not; so:
rm -r /mnt/media/*

echo; echo -n "installation completed successfully"
answer="$(printf "no\nyes" | fzy -p "reboot the system? ")"
[ "$answer" = yes ] && systemctl reboot
