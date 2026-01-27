#!/usr/bin/env sh

# mounting and formatting storage devices

[ "$1" = mount ] && [ -n "$2" ] {
	device_name="$(echo "$2" | sed -n "s@/dev/@@p")"
	[ -b "/dev/$device_name" ] || {
		echo "no block device in \"/dev/$device_name\""
		exit 1
	}
	
	fstype="$(blkid /dev/"$device_name" | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
	if [ "$fstype" = vfat ]; then
		# it seems that vfat does not mount with discard as default (unlike btrfs)
		# if queued trim is supported, use discard option when mounting
		discard_opt=
		if [ "$(cat /sys/block/"$device_name"/queue/discard_granularity)" -gt 0 ] &&
			[ "$(cat /sys/block/"$device_name"/queue/discard_max_bytes)" -gt 2147483648 ]
		then
			discard_opt="discard,"
		fi
		mount -o ${discard_opt}nosuid,nodev,uid=$(id -u nu),gid=$(id -g nu) "$2" /nu/.local/state/mounts/"$device_name"
	else
		mount -o nosuid,nodev "$2" /nu/.local/state/mounts/"$device_name"
	fi
	exit
}

[ "$1" = unmount ] && [ -n "$2" ] && {
	mount_point="$2"
	
	# before unmount, run "fstrim <mount-point>" for devices supporting unqueued trim
	# [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
	# [ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -lt 2147483648 ] &&
	
	# /nu/.local/state/mounts/"$(basename "$2")"
	
	exit
}

target_device="$(echo "$3" | sed -n "s@/dev/@@p")"

is_interactive=false
[ "$1" = format-sys ] && is_interactive=true
[ "$1" = format-inst ] && [ -z "$target_device" ] && is_interactive=true
$is_interactive && {
	echo; echo "available storage devices:"
	printf "\tname\tsize\tmodel\n"
	printf "\t----\t----\t-----\n"
	ls -1 --color=never /sys/block/ | sed -n '/^loop/!p' | while read -r device_name; do
		device_size="$(cat /sys/block/"$device_name"/size)"
		device_size="$((device_size / 1000000))GB"
		device_model="$(cat /sys/block/"$device_name"/device/model)"
		printf "\t$device_name\t$device_size\t$device_model\n"
	done
	printf "enter the name of the target device for installation: "
	read -r target_device
}

[ -e /sys/block/"$target_device" ] || {
	echo "there is no storage device named \"$target_device\""
	exit 1
}

# if $target_device is a partition, set it to the parent device
target_device_num="$(cat /sys/class/block/"$target_device"/dev | cut -d ":" -f 1):0"
target_device="$(basename "$(readlink /dev/block/"$target_device_num")")"

# exit if $target_device is the root device
root_partition="$(mount -l | grep " on / " | cut -d ' ' -f 1 | sed -n "s@/dev/@@p")"
root_device_num="$(cat /sys/class/block/"$root_partition"/dev | cut -d ":" -f 1):0"
root_device="$(basename "$(readlink /dev/block/"$root_device_num")")"
if [ "$(stat -L -c %d:%i "/dev/$target_device")" = "$(stat -L -c %d:%i "/dev/$root_device")"]; then
	echo "can't install on \"$target_device\"; it contains the running system"
	exit 1
fi

[ "$1" = format ] && [ "$2" = backup ] && {
	mkfs.btrfs -f /dev/"$target_device"
	mount_dir="$(mktemp -d)"
	trap "trap - EXIT; umount '$mount_dir'; rmdir '$mount_dir'" EXIT INT TERM QUIT HUP PIPE
	mount /dev/"$target_device" "$mount_dir"
	chmod 777 "$mount_dir"
	exit
}
[ "$1" = format ] && [ "$2" = fat ] && {
	mkfs.vfat -I -F 32 /dev/"$target_device"
	exit
} 
[ "$1" = format ] && [ "$2" = exfat ] && {
	mkfs.exfat /dev/"$target_device"
	exit
} 

if [ "$1" != format-inst ] && [ "$1" != format-sys ] || [ -z "$2" ]; then
	echo "usage:"
	echo "	sd mount <dev-name>"
	echo "	sd unmount <mount-point>"
	echo "	sd format backup|fat|exfat <dev-name>"
	echo "	sd format-inst <target-path> [<dev-name>]"
	echo "	sd format-sys <target-path>"
	exit 1
fi

target_dir="$2"
mkdir -p "$target_dir" || exit

[ "$1" = format-inst ] && {
	$is_interactive && {
		printf "WARNING! all the data on \"/dev/$target_device\" will be erased; continue? (y/N) "
		read -r answer
		[ "$answer" = y ] || exit
	}
	# create a UEFI partition, and format it with FAT32
	printf "g\nn\n1\n\n\nt\nuefi\nw\nq\n" | fdisk -w always /dev/"$target_device"
	mkfs.vfat -F 32 /dev/"$target_device"
	mount "$target_device" "$target_dir"
	exit
}

# the following is run only when "$1" is "format-sys"

do_repaire() {
	local target_device="$1" target_partitions= target_partition1_fstype= target_partition2_fstype=
	
	target_partitions="$(echo /sys/block/"$target_device"/"$target_device"* |
		sed -n "s/\/sys\/block\/$target_device\///pg")"
	target_partition1="$(echo "$target_partitions" | cut -d " " -f1)"
	target_partition2="$(echo "$target_partitions" | cut -d " " -f2)"
	fdisk -l /dev/"$target_device" | sed -n "/$target_partition1.*EFI System/p" | {
		read -r line
		[ -n "$line" ] && target_partition1_is_efi=true
	}
	target_partition1_fstype="$(blkid /dev/"$target_partition1" | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
	target_partition2_fstype="$(blkid /dev/"$target_partition2" | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
	
	# if the target device has a uefi vfat, and a LUKS encrypted BTRFS partition,
	# try to to use the current partitions instead of wiping them off
	
	[ "$target_partition1_is_efi" = true ] &&
	[ "$target_partition1_fstype" = vfat ] &&
	[ "$target_partition2_fstype" = luks ] &&
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
		done
		root_fstype="$(blkid /dev/mapper/rootfs | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
		if [ "$root_fstype" = btrfs ]; then
			break
		else
			echo "can't use the root partition, cause its file system is not BTRFS"
			answer=n
		fi
		[ "$answer" = n ]
	} || {
		printf "WARNING! all the data on \"/dev/$target_device\" will be erased; continue? (y/N) "
		read -r answer
		[ "$answer" = y ] || exit
		false
	}
}

do_repaire "$target_device" || {
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
	cryptsetup luksFormat --batch-mode --key-file="$luks_key_file" "$target_partition2" || exit 1
	# other than a key'based slot, create a password based slot
	# warn the user that the passwrod must not be used carelessly
	# only if the system is tampered it will ask for the password
	# use password only if you are sure that the source of tamper is yourself
	cryptsetup luksAddKey --key-file "$luks_key_file" "$target_partition2" || exit 1
	cryptsetup open --allow-discards --persistent --type luks --key-file "$luks_key_file" "$target_partition2" "rootfs"
	
	mkfs.btrfs -f --quiet "/dev/mapper/rootfs" || exit
}

mount /dev/mapper/rootfs "$target_dir" || exit

mkdir -p "$target_dir"/boot
mount "$target_partition1" "$target_dir"/boot || exit

# systemd bootloader
cryptroot_uuid="$(blkid "$target_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
modules="nvme,sd-mod,usb-storage,btrfs"
[ -e /sys/module/vmd ] && modules="$modules,vmd"
mkdir -p "$target_dir"/boot/loader/entries
printf "title Linux
linux /efi/boot/vmlinuz
initrd /efi/boot/ucode.img
initrd /efi/boot/initramfs
options cryptkey=EXEC=tpm-getkey cryptroot=UUID=$cryptroot_uuid cryptdm=rootfs
options root=/dev/mapper/rootfs rootfstype=btrfs rootflags=rw,noatime modules=$modules quiet
" > "$target_dir"/boot/loader/entries/linux.conf
printf 'default linux.conf
timeout 0
auto-entries no
' > "$target_dir"/boot/loader/loader.conf

# it seems that vfat does not mount with discard as default (unlike btrfs)
# so if queued trim is supported, use discard option when mounting boot
boot_mountopt=""
if [ "$(cat /sys/block/"$target_device"/queue/discard_granularity)" -gt 0 ] &&
	[ "$(cat /sys/block/"$target_device"/queue/discard_max_bytes)" -gt 2147483648 ]
then
	boot_mountopt="discard,"
fi

# fstab
boot_uuid="$(blkid "$taget_partition1" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
mkdir -p "$target_dir"/var/etc
printf "UUID=$boot_uuid /boot vfat ${boot_mountopt}rw,noatime 0 0
" > "$target_dir"/var/etc/fstab

mkdir -p "$target_dir"/var/lib/luks
[ -n "$luks_key_file" ] && cat "$luks_key_file" > "$target_dir"/var/lib/luks/key0
dd if=/dev/random of="$target_dir"/var/lib/luks/key1 bs=32 count=1 status=none
dd if=/dev/random of="$target_dir"/var/lib/luks/key2 bs=32 count=1 status=none
chmod 600 "$target_dir"/var/lib/luks/key0
chmod 600 "$target_dir"/var/lib/luks/key1
chmod 600 "$target_dir"/var/lib/luks/key2
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 0 "$target_partition2" "$target_dir"/var/lib/luks/key0
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 1 "$target_partition2" "$target_dir"/var/lib/luks/key1
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 2 "$target_partition2" "$target_dir"/var/lib/luks/key2
