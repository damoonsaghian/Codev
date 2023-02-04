set -e

. "$(dirname "$0")/pick.sh"

project_path="$(dirname "$0")/.."

echo 'select a CPU architecture:'
pick arch 'riscv64\nppc64le\naarch64\narmv7\nx86_64\nx86\ns390x'

url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$arch"
# find the version number of the latest stable release
version="$(wget -q -O- "$url/latest-releases.yaml" | grep "version:" | head -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)"

# download and verify Alpine live iso file
mkdir -p "$project_path/.cache/alpine"
cd "$project_path/.cache/alpine"
# remove old files
rm -f $(echo alpine-standard-*-"$arch".iso | sed s/"alpine-standard-$version-$arch.iso"//)
wget --continue "$url/alpine-standard-$version-$arch.iso" || true
wget --continue "$url/alpine-standard-$version-$arch.iso.sha256"
sha256sum --check --status "alpine-standard-$version-$arch.iso.sha256" || {
	echo "verifying the checksum of the downloaded file failed; try again"
	rm -f "alpine-standard-$version-$arch.iso" "alpine-standard-$version-$arch.iso.sha256"
	exit 1
}
# when Alpine starts to sign the checksum files with alpine-keys, verify the signature too

# if we're on a live Alpine system, copy kernel modules from modloop and unmount loopback device
# so we can create the customized live system on the booted device itself
DO_UMOUNT=1 copy-modloop || true

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
echo "select a storage device to make an Alpine Linux live system on it:"
pick device "$(show_block_devices)"
device_name="$(echo "$device" | cut -d ' ' -f 1)"
printf "all data on \"$device_name\" will be deleted; do you want to continue? (y/N): "
read answer
[ "$answer" = y ] || exit

# if "sd" command is available use that, cause it can be run by non'root users
sd_command_exists=false
sd >/dev/null && sd_command_exists=true

# create partition table (ppc64le and s390x need additional partitions)
# on s390x, DASD is not supported use SCSI instead
if $sd_command_exists; then
	sd part "$device_name" ",uefi"
else
	apk add sfdisk
	echo "1M,,uefi" | sfdisk --quiet --wipe always --label gpt "$device_name"
fi
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
# format it with VFAT
if $sd_command_exists; then
	sd format "$device_name" vfat
else
	apk add dosfstools
	mkfs.vfat "/dev/$device_name"
fi

# bootloader
# https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
# initialize MBR for syslinux only
#if [ "$BOOTLOADER" = "syslinux" ] && [ -f "$MBR" ]; then
#	cat "$MBR" > $diskdev
#fi

if $sd_command_exists; then
	sd mount "$device_name"
else
	mkdir -p "$HOME/.local/mount/$device_name"
	mount "/dev/$device_name" "$HOME/.local/mount/$device_name"
fi

# extract the Alpine live iso file into the usb storage
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-bootable.in
if $sd_command_exists; then
	sd loop "$project_path/.cache/$iso_file"
	cp -r "$project_path/.cache/$iso_file"-loop/* "$HOME/.local/mount/$device_name"
	sd unloop "$project_path/.cache/$iso_file"
else
fi

initramfs_append_path="$project_path/.cache/initramfs-append"

# include the comshell files into the initramfs
mkdir -p "$initramfs_append_path/comshell"
cp -r "$project_path"/* "$initramfs_append_path/comshell/"

# add Intel and AMD microcodes to the live media
[ "$arch" = x86_64 ] || [ "$arch" = x86 ] && {
	apk add intel-ucode amd-ucode
	cp /boot/intel-ucode.img "$HOME/.local/mount/$device_name/boot/intel-ucode.img"
	cp /boot/amd-ucode.img "$HOME/.local/mount/$device_name/boot/amd-ucode.img"
	# /boot/syslinux/syslinux.cfg
	# INITRD /boot/intel-ucode.img,/boot/amd-ucode.img,/boot/initramfs-lts
	# /boot/grub/grub.cfg
	# initrd	/boot/intel-ucode.img /boot/amd-ucode.img /boot/initramfs-lts
}

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
find . | cpio -H newc -o | gzip >> "$HOME/.local/mount/$device_name"
rm -rf "$initrd_append_path"

if $sd_command_exists; then
	sd unmount "$device_name"
else
	umount "$HOME/.local/mount/$device_name"
fi
echo "Alpine live media created successfully"
echo "you can now remove the media"
