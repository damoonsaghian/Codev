set -e
. /lib/libalpine.sh

# copy kernel modules from modloop and unmount loopback device
# so we can create the customized live system on the booted device itself
DO_UMOUNT=1 copy-modloop

show_block_devices() {
	local p= dev= disks= disk= model= d= size=
	for p in /sys/block/*/device; do
		dev="${p%/device}"
		dev=${dev#/sys/block/}
		disks="$disks $dev"
	done
	for disk in $disks; do
		dev="${disk#/dev/}"
		d=$(echo $dev | sed 's:/:!:g')
		model=$(cat /sys/block/$d/device/model 2>/dev/null)
		size=$(awk '{gb = ($1 * 512)/1000000000; printf "%.1f GB\n", gb}' /sys/block/$d/size 2>/dev/null)
		printf "\t%-10s %s\t%s\n" "$dev" "$size" "$model"
	done
}

echo 'storage devices:'
show_block_devices
printf 'choose a storage device to make a live system on it: '
read device_name
ask_yesno "all data on \"$device_name\" will be deleted; do you want to continue? (y/n)" || exit

# usage: setup_partitions <diskdev> size1,type1 [size2,type2 ...]
setup_partitions() {
	local diskdev="$1" start=1M line=
	shift

	# create clean disk label
	echo "label: $DISKLABEL" | sfdisk --quiet $diskdev

	# initialize MBR for syslinux only
	if [ "$BOOTLOADER" = "syslinux" ] && [ -f "$MBR" ]; then
		cat "$MBR" > $diskdev
	fi

	# create new partitions
	(
		for line in "$@"; do
			case "$line" in
			0M*) ;;
			*) echo "$start,$line"; start= ;;
			esac
		done
	) | sfdisk --quiet --wipe-partitions always --label $DISKLABEL $diskdev || return 1

	# create device nodes if not exist
	$MOCK mdev -s
}

sd=sd
sd >/dev/null || sd="sh \"$(dirname "$0")/sd\""

# create partition table (ppc64le and s390x need additional partitions)
$sd part
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
# format it with VFAT

# bootloader
# https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in

$sd mount "$device_name"

# download and extract the latest iso into the usb storage
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-bootable.in
$sd loop "$project_path/.cache/$iso_file"
cp -r /run/mount/loop/* /run/mount/"$device_name"
$sd unloop

project_path="$(dirname "$0")/.."
initramfs_append_path="$project_path/.cache/initramfs-append"

# include the comshell files into the initramfs
mkdir -p "$initramfs_append_path/comshell"
cp -r "$project_path"/* "$initramfs_append_path/comshell/"

# manipulate initramfs to automatically login as root
mkdir -p "$initramfs_append_path/etc"
cat <<__EOF__ > "$initramfs_append_path/etc/inittab"
# /etc/inittab
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
# Set up a couple of getty's
tty1::respawn:/bin/login -f root
#tty1::respawn:/sbin/getty 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
tty3::respawn:/sbin/getty 38400 tty3
tty4::respawn:/sbin/getty 38400 tty4
tty5::respawn:/sbin/getty 38400 tty5
tty6::respawn:/sbin/getty 38400 tty6
# Put a getty on the serial port
#ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100
# Stuff to do for the 3-finger salute
::ctrlaltdel:/sbin/reboot
# Stuff to do before rebooting
::shutdown:/sbin/openrc shutdown
__EOF__

# manipulate initramfs to automatically run "setup.sh"
mkdir -p "$initramfs_append_path/etc/profile.d"
echo 'sh /comshell/alpine/setup.sh' > "$initramfs_append_path/etc/profile.d/zzz-setup.sh"

# append the files to initramfs
cd "$initramfs_append_path"
find . | cpio -H newc -o | gzip >> "/run/mount/$device_name/boot/initramfs-lts"
rm -rf "$initrd_append_path"
