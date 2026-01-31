#!/usr/bin/env sh

# mounting and formatting storage devices

usage_error() {
	echo "usage:"
	echo "	sd mount <dev-name>"
	echo "	sd unmount <dev-name>"
	echo "	sd format backup|fat|exfat <dev-name>"
	echo "	sd format-inst <target-path> [<dev-name>]"
	echo "	sd format-sys <target-path>"
	exit 1
}

[ "$1" = mount ] && {
	[ -n "$2" ] && usage_error
	
	device_name="$(basename "$2")"
	[ -e /sys/block/"$device_name" ] || {
		echo "there is no storage device named \"$device_name\""
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
		
		if [ -n "$SUDO_UID" ] && [ -n "$SUDO_GID" ]; then
			mount -o ${discard_opt}nosuid,nodev,uid="$SUDO_UID",gid="$SUDO_GID" "$2" /nu/.local/state/mounts/"$device_name"
		else
			mount -o ${discard_opt}nosuid,nodev "$2" /nu/.local/state/mounts/"$device_name"
		fi
	else
		mount -o nosuid,nodev "$2" /nu/.local/state/mounts/"$device_name"
	fi
	exit
}

[ "$1" = unmount ] && {
	[ -n "$2" ] && usage_error
	
	device_name="$(basename "$2")"
	mount_point=/nu/.local/state/mounts/"$device_name"
	[ -d "$mount_point" ] || {
		echo "there is no mounted storage device named \"$device_name\""
		exit 1
	}
	
	# run fstrim for devices supporting unqueued trim
	[ "$(cat /sys/block/"$device_name"/queue/discard_granularity)" -gt 0 ] &&
	[ "$(cat /sys/block/"$device_name"/queue/discard_max_bytes)" -lt 2147483648 ] &&
		fstrim "$mount_point"
	
	umount "$mount_point"
	exit
}

[ "$1" != format ] && [ "$1" != format-inst ] && [ "$1" != format-sys ] && usage_error

target_device="$(basename "$3")"

is_interactive=false
[ "$1" = format-sys ] && is_interactive=true
[ "$1" = format-inst ] && [ -z "$target_device" ] && is_interactive=true
$is_interactive && {
	echo; echo "available storage devices:"
	printf "\tname\tsize\tmodel\n"
	printf "\t----\t----\t-----\n"
	ls -1 /sys/block/ | sed -n '/^loop/!p' | while read -r device_name; do
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
if [ "$target_device" = "$root_device" ]; then
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
	usage_error
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
	target_device_p1_num="$(cat /sys/class/block/"$target_device"/dev | cut -d ":" -f 1):1"
	target_device_p1="$(basename "$(readlink /dev/block/"$target_device_p1_num")")"
	mkfs.vfat -F 32 "/dev/$target_device_p1"
	mount "/dev/$target_device_p1" "$target_dir"
	exit
}

# the following is run only when "$1" is "format-sys"

do_repaire() {
	local target_device="$1" target_partitions=''
	local target_partition1_fstype='' target_partition2_fstype=''
	local target_partition1_is_efi=''
	
	target_partitions="$(echo /sys/block/"$target_device"/"$target_device"* |
		sed -n "s/\/sys\/block\/$target_device\///pg")"
	target_partition1="$(echo "$target_partitions" | cut -d " " -f1)"
	target_partition2="$(echo "$target_partitions" | cut -d " " -f2)"
	target_partition1_is_efi="$(fdisk -l /dev/"$target_device" | sed -n "/$target_partition1.*EFI System/p")"
	[ -n "$target_partition1_is_efi" ] && target_partition1_is_efi=true
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
					[ "$answer" = n ] && return
				}
			}
		done
		root_fstype="$(blkid /dev/mapper/rootfs | sed -rn 's/.*TYPE="(.*)".*/\1/p')"
		if [ "$root_fstype" = btrfs ]; then
			return 0
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
	cryptsetup luksFormat --batch-mode --key-file "$luks_key_file" "$target_partition2" || exit
	# other than a key'based slot (in slot 0), create a password based slot (in slot 1)
	echo; echo "set the password for encryption of root partition"
	echo "WARNING! do not use this password carelessly"
	echo "in practice, it's only required when restoring your data from a backup, on a new system"
	cryptsetup luksAddKey --key-file "$luks_key_file" "$target_partition2" || exit
	cryptsetup open --allow-discards --persistent --type=luks --key-file "$luks_key_file" "$target_partition2" "rootfs"
	
	mkfs.btrfs -f --quiet "/dev/mapper/rootfs" || exit
}

mount /dev/mapper/rootfs "$target_dir" || exit

mkdir -p "$target_dir"/boot
mount "$target_partition1" "$target_dir"/boot || exit

mkdir -p "$target_dir"/var/lib/luks
[ -z "$luks_key_file" ] && luks_key_file="$target_dir"/var/lib/luks/key1
cat "$luks_key_file" > "$target_dir"/var/lib/luks/key1
dd if=/dev/random of="$target_dir"/var/lib/luks/key1 bs=32 count=1 status=none
dd if=/dev/random of="$target_dir"/var/lib/luks/key2 bs=32 count=1 status=none
chmod 600 "$target_dir"/var/lib/luks/key1
chmod 600 "$target_dir"/var/lib/luks/key2
chmod 600 "$target_dir"/var/lib/luks/key3
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 2 "$target_partition2" "$target_dir"/var/lib/luks/key2 || exit
cryptsetup luksAddKey --keyfile "$luks_key_file" --new-key-slot 3 "$target_partition2" "$target_dir"/var/lib/luks/key3 || exit

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

# fstab
# it seems that vfat does not mount with discard as default (unlike btrfs)
# so if queued trim is supported, use discard option when mounting boot
discard_opt=""
if [ "$(cat /sys/block/"$target_device"/queue/discard_granularity)" -gt 0 ] &&
	[ "$(cat /sys/block/"$target_device"/queue/discard_max_bytes)" -gt 2147483648 ]
then
	discard_opt="discard,"
fi
boot_uuid="$(blkid "$target_partition1" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
mkdir -p "$target_dir"/var/etc
printf "UUID=$boot_uuid /boot vfat ${discard_opt}rw,noatime 0 0
" > "$target_dir"/var/etc/fstab
