#!/usr/bin/env sh

# mounting and formatting storage devices

[ "$1" = mount ] && {
	# mount with suid bits disabled
	# mount to ~/.local/state/mounts
	
	# it seems that vfat does not mount with discard as default (unlike btrfs)
	# if queued trim is supported, use discard option when mounting
	if [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
		[ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -gt 2147483648 ]
	then
	fi
	exit
}

[ "$1" = unmount ] && {
	# before unmount, run "fstrim <mount-point>" for devices supporting unqueued trim
	# [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
	# [ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -lt 2147483648 ] &&
	exit
}

[ "$1" = format ] && {
	# format devices
	# type: fat
	# mkfs-args: -F, 32, -I (to override partitions)
	# format non'system devices, format with vfat or exfat (if wants files bigger than 4GB)
	# for system devices:
	# doas sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"
	exit
}

if [ "$1" != mksys ] && [ "$1" != format-inst ]; then
	echo "usage:"
	echo "	sd mount <dev-name>"
	echo "	sd unmount <mount-point>"
	echo "	sd format <dev-name>"
	echo "	sd mksys"
	exit 1
fi

target_dir="$2"
if [ -z "$target_dir" ]; then
	target_dir=target
fi

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

test -e /sys/block/"$target_device" || {
	echo "there is no storage device named \"$target_device\""
	exit 1
}

# if target_device is a partition, find the parent device
/sys/class/block/"$target_device"/dev
target_device_num="$(cat /sys/class/block/"$target_device"/dev | cut -d ":" -f 1):0"
target_device="$(basename "$(readlink /dev/block/"$target_device_num")")"

# exit if $target_device is the system device
root_partition="$(df / | tail -n 1 | cut -d " " -f 1 | cut -d / -f 3)"
root_device_num="$(cat /sys/class/block/"$root_partition"/dev | cut -d ":" -f 1):0"
root_device="$(basename "$(readlink /dev/block/"$root_device_num")")"
if [ "$(stat -L -c %d:%i "/dev/$target_device")" = "$(stat -L -c %d:%i "/dev/$root_device")"]; then
	echo "can't install on \"$target_device\", since it contains the running system"
	exit 1
fi

[ "$1" = format-inst ] && {
	# create a UEFI partition, and format it with FAT32
	printf "g\nn\n1\n\n\nt\nuefi\nw\nq\n" | fdisk -w always /dev/"$target_device"
	mkfs.vfat -F 32 /dev/"$target_device"
	mount "$target_device" "$target_dir"
	exit
}

# the following is run only when "$1" is "mksys"

usr_subvol="$3"

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
	cryptsetup luksFormat --batch-mode --key-file="$luks_key_file" "$target_partition2" || exit 1
	# other than a key'based slot, create a password based slot
	# warn the user that the passwrod must not be used carelessly
	# only if the system is tampered it will ask for the password
	# use password only if you are sure that the source of tamper is yourself
	cryptsetup luksAddKey --key-file "$luks_key_file" "$target_partition2" || exit 1
	cryptsetup open --allow-discards --persistent --type luks --key-file "$luks_key_file" "$target_partition2" "rootfs"
	
	mkfs.btrfs -f --quiet "/dev/mapper/rootfs" || exit 1
fi

mount /dev/mapper/rootfs "$target_dir" || exit 1

if [ -n "$usr_subvol" ]; then
	btrfs subvolume create "$target_dir/$usr_subvol"
	mkdir "$target_dir"/usr
	mount --bind "$target_dir/$usr_subvol" "$target_dir"/usr || exit 1
fi

mkdir -p "$target_dir"/boot
mount "$taget_partition1" "$target_dir"/boot || exit 1

# systemd bootloader
cryptroot_uuid="$(blkid "$target_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
modules="nvme,sd-mod,usb-storage,btrfs"
[ -e /sys/module/vmd ] && modules="$modules,vmd"
usr_option=
[ -n "$usr_subvol" ] && usr_option="usrflags=subvol=/$usr_subvol,ro,noatime"
mkdir -p "$target_dir"/boot/loader/entries
printf "title Linux
linux /efi/boot/vmlinuz
initrd /efi/boot/ucode.img
initrd /efi/boot/initramfs
options cryptkey=EXEC=tpm-getkey cryptroot=UUID=$cryptroot_uuid cryptdm=rootfs
options root=/dev/mapper/rootfs rootfstype=btrfs rootflags=rw,noatime $usr_option \
options modules=$modules quiet
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
/dev/mapper/rootfs /usr btrfs noauto 0 0
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
