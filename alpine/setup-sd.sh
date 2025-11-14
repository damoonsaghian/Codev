target_device="$1"
if [ -z "$target_device" ]; then
	echo; echo "available storage devices:"
	printf "\tname\tsize\tmodel\n"
	printf "\t----\t----\t-----\n"
	ls -1 --color=never /sys/block/ | sed -n '/^loop/!p' | while read -r device_name; do
		device_size="$(cat /sys/block/"$device_name"/size)"
		device_size="$((device_size / 1000000))GB"
		device_model="$(cat /sys/block/"$device_name"/device/model)"
		printf "\t$device_name\t$device_size\t$device_model\n"
	done
	printf "enter the name of the device to install SPM Linux on: "
	read -r target_device
	test -e /sys/block/"$target_device" || {
		echo "there is no storage device named \"$target_device\""
		exit 1
	}
	
	root_partition="$(df / | tail -n 1 | cut -d " " -f 1 | cut -d / -f 3)"
	root_device_num="$(cat /sys/class/block/"$root_partition"/dev | cut -d ":" -f 1):0"
	root_device="$(basename "$(readlink /dev/block/"$root_device_num")")"
	if [ "$target_device" = "$root_device" ]; then
		echo "can't install on \"$target_device\", since it contains the running system"
		exit 1
	fi
fi

if ["$(basename "$0")" = spm ]; then
	# this script is run through "spm new" command
	# so we should install Alpine Linux on a removable storage device
	
	# in EFI partition with vfat format:
	# if the file date is not older than 1 month, exit
	# unified kernel image, signed by current systems key
	# it only includes programs needed to install Alpine on a system, plus the content of this project
fi

target_partitions="$(echo /sys/block/"$target_device"/"$target_device"* |
	sed -n "s/\/sys\/block\/$target_device\///pg")"
target_partition1="$(echo "$target_partitions" | cut -d " " -f1)"
target_partition2="$(echo "$target_partitions" | cut -d " " -f2)"
fdisk -l /dev/"$target_device" | sed -n "/$target_partition1.*EFI System/p" | {
	read -r line
	test -n "$line" && target_partition1_is_efi=true
}
target_partition1_fstype="$(blkid /dev/"$target_partition1" | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
target_partition2_fstype="$(blkid /dev/"$target_partition2" | sed -rn 's/.*TYPE="(.*)".*/\1/p')"

# if the target device has a uefi vfat, and a BTRFS partition,
# ask the user whether to to use the current partitions instead of wiping them off
if [ "$target_partition1_is_efi" != true ] ||
	[ "$target_partition1_fstype" != vfat ] ||
	[ "$target_partition2_fstype" != btrfs ] ||
	{
		echo "it seems that the target device is already partitioned properly"
		printf "do you want to keep the partitions? (Y/n) "
		read -r answer
		[ "$answer" = n ]
	}
then
	printf "WARNING! all the data on \"/dev/$target_device\" will be erased; continue? (y/N) "
	read -r answer
	[ "$answer" = y ] || exit
	
	# create partitions
	{
	echo g # create a GPT partition table
	echo n # new partition
	echo 1 # make it partition number 1
	echo # default, start at beginning of disk 
	echo +260M # boot parttion
	echo t # change partition type
	echo uefi
	echo n # new partition
	echo 2 # make it partion number 2
	echo # default, start immediately after preceding partition
	echo # default, extend partition to end of disk
	echo w # write the partition table
	echo q # quit
	} | fdisk -w always "/dev/$target_device" > /dev/null
	
	target_partitions="$(echo /sys/block/"$target_device"/"$target_device"* |
		sed -n "s/\/sys\/block\/$target_device\///pg")"
	target_partition1="$(echo "$target_partitions" | cut -d " " -f1)"
	target_partition2="$(echo "$target_partitions" | cut -d " " -f2)"
	
	
	
	# format the partitions
	apk add btrfs-progs
	modprobe btrfs
	mkfs.vfat -F 32 "$target_partition1"
	mkfs.btrfs -f --quiet "$target_partition2"
	
	apk add cryptsetup
	# create full disk encryption using TPM2
	# https://news.opensuse.org/2025/07/18/fde-rogue-devices/
	# https://microos.opensuse.org/blog/2023-12-20-sdboot-fde/
	# https://en.opensuse.org/Portal:MicroOS/FDE
	# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
	# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
	# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/
	#
	# secure boot:
	# , enable secure boot, using custom keys (using efivar)
	# , lock UEFI
	# , when kernel is updated sign kernel and initrd
	# https://security.stackexchange.com/a/281279
	# use efivar to:
	# , enable DMA protection (IOMMU) in UEFI, to make USB4 secure
	# , set UEFI password
	
	# https://wiki.archlinux.org/title/Btrfs#Swap_file
fi