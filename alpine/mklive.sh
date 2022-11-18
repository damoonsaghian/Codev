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
read device
ask_yesno "all data on \"$device\" will be deleted; do you want to continue? (y/n)" || exit

# create partition table (ppc64le and s390x need additional partitions)
# if available do it with "sd"
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
# format it with VFAT

# download and extract the latest iso into the usb storage
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-bootable.in

mkdir /mnt/boot/initramfs-extract
cd /mnt/boot/initramfs-extract
bsdcat ../initramfs* | bsdcpio -i

# include the comshell files into the initramfs
cp -r "$(dirname "$0")" /mnt/boot/initramfs-extract

# manipulate initramfs to login as root, and run "sh /comshell/install.sh" automatically
cat <<__EOF__ > /etc/inittab
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
echo 'sh /alpine/setup.sh' > /etc/profile.d/zzz-install.sh

rm -f ../initramfs*
find . | bsdcpio -oz --format=newc > ../initramfs*
cd ~
rm -rf /mnt/boot/initramfs-extract

# bootloader
# https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
