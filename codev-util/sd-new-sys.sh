target_device="$1"
removable_storage="$2"

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

if [ -n "$removable_storage" ]; then
	# this script is run through "spm new" command
	# ask user for mode of installation
	# , intall on internal storage device
	# , install on removable storage device (to install Alpine on another system)
	
	if [ "$installation_mode" = removable ]; then
		# if the device does not have one EFI partition of at least 500MB size with fat32 format, create it
		# create  an initramfs that includes programs needed to install Alpine, plus the content of this project
		# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
		exit
	fi
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

# if the target device has a uefi vfat, and a LUKS encrypted BTRFS partition,
# ask the user whether to to use the current partitions instead of wiping them off
if [ "$target_partition1_is_efi" != true ] ||
	[ "$target_partition1_fstype" != vfat ] ||
	[ "$target_partition2_fstype" != luks ] ||
	{
		echo "it seems that the target device is already partitioned properly"
		printf "do you want to keep the partitions? (Y/n) "
		read -r answer
		[ "$answer" != n ] && while [ "$answer" != n ]; do
			echo "enter the password to open the encrypted root partition"
			cryptsetup open --allow-discards --persistent --type luks  "$target_partition2" "root" || {
				echo "you entered wrong password to decrypt root partition; try again? (Y/n) "
				read -r answer
				[ "$answer" = n ] && break
			}
			root_fstype="$(blkid /dev/mapper/root | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
			[ "$root_fstype" = btrfs ] || {
				echo "can't use the root partition, cause its file system is not BTRFS"
				answer=n
			}
		}
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
	
	mkfs.vfat -F 32 "$target_partition1"
	
	luks_key_file="$(mktemp)"
	dd if=/dev/random of="$luks_key_file" bs=32 count=1 status=none
	cryptsetup luksFormat --batch-mode --key-file="$luks_key_file" "$target_partition2"
	# other than a key'based slot, create a password based slot
	# warn the user that the passwrod must not be used carelessly
	# only if the system is tampered it will ask for the password
	# use password only if you are sure that the source of tamper is yourself
	cryptsetup luksAddKey --key-file "$luks_key_file" "$target_partition2"
	cryptsetup open --allow-discards --persistent --type luks --key-file "$luks_key_file" "$target_partition2" "rootfs"
	
	mkfs.btrfs -f --quiet "/dev/mapper/rootfs"
	
	# https://wiki.archlinux.org/title/Btrfs#Swap_file
fi

boot_uuid="$(blkid "$taget_partition1" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
cryptroot_uuid="$(blkid "$taget_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"

rootfs_mount="$(mktemp -d)"
mount /dev/mapper/rootfs "$rootfs_mount"
btrfs subvolume create "$rootfs_mount"/root
btrfs subvolume create "$rootfs_mount"/var
btrfs subvolume create "$rootfs_mount"/home
umount "$rootfs_mount"; rmdir "$rootfs_mount"; rootfs_mount=""

new_root="$(mktemp -d)"
mount /dev/mapper/roofs -o subvol=root "$new_root"
mkdir -p "$new_root"/root/var
mount /dev/mapper/roofs -o subvol=var "$new_root"/root/var
mkdir -p "$new_root"/root/home
mount /dev/mapper/roofs -o subvol=home "$new_root"/root/home

cat "$luks_key_file" > "$new_root"/var/lib/luks/key1
chmod 600 "$new_root"/var/lib/luks/key1
dd if=/dev/random of="$new_root"/var/lib/luks/key2 bs=32 count=1 status=none
dd if=/dev/random of="$new_root"/var/lib/luks/key3 bs=32 count=1 status=none
chmod 600 "$new_root"/var/lib/luks/key2
chmod 600 "$new_root"/var/lib/luks/key3
cryptsetup luksAddKey --keyfile "$luks_key_file" "$target_partition2" "$new_root"/var/lib/luks/key2
cryptsetup luksAddKey --keyfile "$luks_key_file" "$target_partition2" "$new_root"/var/lib/luks/key3

mkdir -p "$new_root"/boot
mount "$taget_partition1" "$new_root"/boot

echo "$boot_uuid"
echo "$cryptroot_uuid"
echo "$new_root"
