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
echo -n '#!/sbin/openrc-run
command="/bin/login"
command_args="-f root"
' > /etc/init.d/autologin
echo 'sh /comshell/install.sh' > /etc/profile.d/zzz.sh

rm -f ../initramfs*
find . | bsdcpio -oz --format=newc > ../initramfs*
cd ~
rm -rf /mnt/boot/initramfs-extract

# bootloader
# https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device
# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-disk.in
