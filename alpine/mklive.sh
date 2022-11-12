set -e

# stop modloop service, so we create the comshell installer on the live device itself
# https://git.alpinelinux.org/aports/tree/main/openrc/modloop.initd

# ask the user to choose a removable device
removable_devices="$(lsblk --nodep --noheadings -o RM,NAME,SIZE,MODEL | sed -nr 's/^[[:blank:]]+1[[:blank:]]+//p')"
echo 'select a storage device:'
echo '\e[1mwarning!\e[0m all data on the selected storage device will be deleted'
choose device "$removable_devices"
device="$(printf "$device" | cut -d ' ' -f1)"

# create partition table (ppc64le and s390x need additional partitions)
# if available do it with "sd" which does not need root permission
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
# format it with VFAT

# download and extract the latest iso into the usb storage
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-bootable.in

mkdir /mnt/boot/initramfs-extract
cd /mnt/boot/initramfs-extract
bsdcat ../initramfs* | bsdcpio -i
# include the comshell files into the initramfs
cp -r /root/comshell /mnt/boot/initramfs-extract

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
echo 'sh /comshell/install.sh' > /etc/profile.d/zzz-install.sh

rm -f ../initramfs*
find . | bsdcpio -oz --format=newc > ../initramfs*
cd ~
rm -rf /mnt/boot/initramfs-extract

# bootloader
# https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
