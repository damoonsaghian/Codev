script_dir="$(dirname "$(realpath "$0")")"

if [ $(id -u) != 0 ]; then
	echo "this script must be run as root"
	exit 1
fi

# if apk is available:
# create an installer on a removable storage device
# if the device does not have one EFI partition of at least 500MB size with fat32 format, create it
# let user to choose a target architecture
# create an initramfs that includes programs needed to install Alpine, plus codev-utils and codev-shell
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/scripts
# exit

# you need curl installed

# , on a removable storage device, create a UEFI partition, and format it with FAT32
# 	to do those, run these as root:
# 	; fdisk -l # find the name of the device, and write it in place of "sdx" in the following commands
# 	; printf "g\nn\n1\n\n\nt\nuefi\nw\nq\n" | fdisk -w always /dev/sdx
# 	; mkfs.vfat -F 32 /dev/sdx1
# , mount the removable media
# , download Alpine Linux installation media from: https://alpinelinux.org/downloads/
# 	then extract its content into the directory where the removable media was mounted
# , run this: sh alpine/mkovl.sh
# 	that will create a file at ".cache/alpine/localhost.apkovl.tar.gz"
# 	copy that too, into the directory where the removable media was mounted

ovl_dir="$script_dir"/../.cache/alpine/ovl
rm -r "$ovl_dir"
mkdir -p "$ovl_dir"

# this is necessary when using an overlay
mkdir -p "$ovl_dir"/etc
touch "$ovl_dir"/etc/.default_boot_services

mkdir -p "$ovl_dir"/codev
cp -r "$script_dir"/../spm-alpine "$ovl_dir"/codev/
cp -r "$script_dir"/../codev "$ovl_dir"/codev/
cp -r "$script_dir"/../codev-shell "$ovl_dir"/codev/
cp -r "$script_dir"/../codev-util "$ovl_dir"/codev/
cp -r "$script_dir"/../.data "$ovl_dir"/codev/

mkdir -p "$ovl_dir"/root
printf 'sh /codev/alpine/new.sh
' > "$ovl_dir"/root/.profile

print '#!/usr/bin/env sh
exec login -f root
' > "$ovl_dir"/usr/local/bin/autologin
chmod +x "$ovl_dir"/usr/local/bin/autologin

printf '::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
tty1::respawn:/sbin/getty -n -l /usr/local/bin/autologin 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
tty3::respawn:/sbin/getty 38400 tty3
tty4::respawn:/sbin/getty 38400 tty4
tty5::respawn:/sbin/getty 38400 tty5
tty6::respawn:/sbin/getty 38400 tty6
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
' > "$ovl_dir"/etc/inittab

rm -f "$script_dir"/../.cache/alpine/localhost.apkovl.tar.gz
tar --owner=0 --group=0 -czf "$script_dir"/../.cache/alpine/localhost.apkovl.tar.gz "$ovl_dir"

rm -r "$ovl_dir"
