#!/usr/bin/env sh

# mounting and formatting storage devices

# exit if $2 is the system device

[ "$1" = mount ] && {
	# mount with suid bits disabled
	# mount to ~/.local/state/mounts
	
	# it seems that vfat does not mount with discard as default (unlike btrfs)
	# if queued trim is supported, use discard option when mounting
	if [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
		[ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -gt 2147483648 ]
	then
	fi
}

[ "$1" = unmount ] && {
	# before unmount, run "fstrim <mount-point>" for devices supporting unqueued trim
	# [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
	# [ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -lt 2147483648 ] &&
}

[ "$1" = format ] && {
	# format devices
	# type: fat
	# mkfs-args: -F, 32, -I (to override partitions)
	# format non'system devices, format with vfat or exfat (if wants files bigger than 4GB)
	# for system devices:
	# doas sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"
}

[ "$1" = mksys ] || {
	echo "usage:"
	echo "	sd mount <dev-name>"
	echo "	sd unmount <mount-point>"
	echo "	sd format <dev-name>"
	echo "	sd mksys"
}

# the following is run only when "$1" is "mksys"

target_device="$2"
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
			[ -b /dev/mapper/rootfs ] || {
				echo "enter the password to open the encrypted root partition"
				cryptsetup open --allow-discards --persistent --type luks  "$target_partition2" "rootfs" || {
					echo "you entered a wrong password to decrypt root partition; try again? (Y/n) "
					read -r answer
					[ "$answer" = n ] && break
				}
			}
			root_fstype="$(blkid /dev/mapper/rootfs | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
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

# it seems that vfat does not mount with discard as default (unlike btrfs)
# so if queued trim is supported, use discard option when mounting boot
boot_mountopt=""
if [ "$(cat /sys/block/"$target_device"/queue/discard_granularity)" -gt 0 ] &&
	[ "$(cat /sys/block/"$target_device"/queue/discard_max_bytes)" -gt 2147483648 ]
then
	boot_mountopt="discard,"
fi

boot_uuid="$(blkid "$taget_partition1" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
cryptroot_uuid="$(blkid "$taget_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"

rootfs_mount="$(mktemp -d)"
trap "trap - EXIT; umount \"$rootfs_mount\"; rmdir \"$rootfs_mount\"" EXIT INT TERM QUIT HUP PIPE
mount /dev/mapper/rootfs "$rootfs_mount"
btrfs subvolume create "$rootfs_mount"/root
btrfs subvolume create "$rootfs_mount"/var
btrfs subvolume create "$rootfs_mount"/home
umount "$rootfs_mount"; rmdir "$rootfs_mount"; rootfs_mount=""

new_root="$(mktemp -d)"
unmount_all="umount \"$new_root\"/boot; umount \"$new_root\"/var; umount \"$new_root\"/home; \
	umount \"$new_root\"; rmdir \"$new_root\""
trap "exit_status=\$?; trap - EXIT; [ \$exit_status = 0 ] || { $unmount_all; }" EXIT INT TERM QUIT HUP PIPE
mount /dev/mapper/roofs -o subvol=root "$new_root" || exit 1
mkdir -p "$new_root"/root/var
mount /dev/mapper/roofs -o subvol=var "$new_root"/root/var || exit 1
mkdir -p "$new_root"/root/home
mount /dev/mapper/roofs -o subvol=home "$new_root"/root/home || exit 1

[ -n "$luks_key_file" ] && cat "$luks_key_file" > "$new_root"/var/lib/luks/key0
dd if=/dev/random of="$new_root"/var/lib/luks/key1 bs=32 count=1 status=none
dd if=/dev/random of="$new_root"/var/lib/luks/key2 bs=32 count=1 status=none
chmod 600 "$new_root"/var/lib/luks/key0
chmod 600 "$new_root"/var/lib/luks/key1
chmod 600 "$new_root"/var/lib/luks/key2
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 0 "$target_partition2" "$new_root"/var/lib/luks/key0
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 1 "$target_partition2" "$new_root"/var/lib/luks/key1
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 2 "$target_partition2" "$new_root"/var/lib/luks/key2

mkdir -p "$new_root"/boot
mount "$taget_partition1" "$new_root"/boot

echo "$boot_mountopt"
echo "$boot_uuid"
echo "$cryptroot_uuid"
echo "$new_root"
