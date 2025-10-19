# install a minimal Alpine Linux system that runs Codev inside CodevShell
# https://wiki.alpinelinux.org/wiki/Alpine_Linux:Overview
# https://gitlab.alpinelinux.org/alpine
# https://gitlab.alpinelinux.org/alpine/alpine-conf
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/alpine-baselayout
# https://docs.alpinelinux.org/
# https://wiki.alpinelinux.org/wiki/Daily_driver_guide
# https://wiki.alpinelinux.org/wiki/Tutorials_and_Howtos
# https://wiki.alpinelinux.org/wiki/TTY_Autologin
# https://wiki.alpinelinux.org/wiki/Developer_Documentation

if [ $(id -u) != 0 ]; then
	echo "this script must be run as root"
	exit 1
fi

target_device="$1"
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

if ["$(basename "$0")" = spm ]; then
	# this script is run through "spm new" command
	# so we should install Alpine Linux on a removable storage device
	
	# in EFI partition with vfat format:
	# if the file date is not older than 1 month, exit
	# unified kernel image, signed by current systems key
	# it only includes programs needed to install Alpine on a system, plus the content of this project
fi

# if the target device has a uefi vfat, and a BTRFS partition,
# ask the user whether to to use the current partitions instead of wiping them off
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
if [ "$target_partition1_is_efi" != true ] ||
	[ "$target_partition1_fstype" != vfat ] ||
	[ "$target_partition2_fstype" != btrfs ] ||
	{
		echo "it seems that the target device is already partitioned properly"
		printf "do you want to keep the partitions? (Y/n) "
		read -r answer
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
	echo +512M # 512 MB boot parttion
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
	
	# format the partitions
	mkfs.vfat -F 32 "$target_partition1"
	mkfs.btrfs -f --quiet "$target_partition2"
fi

# create full disk encryption using TPM2
# https://news.opensuse.org/2025/07/18/fde-rogue-devices/
# https://microos.opensuse.org/blog/2023-12-20-sdboot-fde/
# https://en.opensuse.org/Portal:MicroOS/FDE
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/
#
# secure boot:
# , enable secure boot, using custom keys (using efivar)
# , lock UEFI
# , when kernel is updated sign kernel and initrd
# https://security.stackexchange.com/a/281279
# use efivar to:
# , enable DMA protection (IOMMU) in UEFI, to make USB4 secure
# , set UEFI password

# https://wiki.archlinux.org/title/Btrfs#Swap_file

setup-interfaces

apk add linux-stable alpine-base musl-locales agetty setpriv chrony acpid eudev dbus doas-sudo-shim bash bash-completion \
	bluez networkmanager NetworkManager-bluetooth wireless-regdb pipewire bash doas gnunet \
	cryptsetup tpm2-tools efivar \
	aria2 pipewire quickshell gnunet

# self signed unified kernel image
# https://wiki.archlinux.org/title/Unified_kernel_image
# https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_your_own_keys
# https://gitlab.alpinelinux.org/alpine/mkinitfs
# https://wiki.archlinux.org/title/Microcode

# to prevent BadUSB, cerate evdev rule that when a new input device is connected:
# touch /tmp/lock-bash
# chown 1000 /tmp/lock-bash

apk add quickshell || {
	# build and install quickshell
}

# codev-shell
# codev
# .data/codev.svg
# doas rules for sd.sh
# codev executable has setgid 10 that lets it to read (password protected) private keys

# update hook for codev-shell codev and quickshell (if "apk add quickshell" fails)

# flatpak: don't allow home dir access

apk add mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-terminal mauikit-documents \
	breeze breeze-icons

apk add qt6-multimedia-imports qt6-webengine-imports qt6-pdf-imports qt6-virtualkeyboard-imports \
	qt6-location qt6-remoteobjects-imports qt6-sensors-imports qt6-texttospeech \
	qt6-charts-imports qt6-graphs-imports qt6-datavisualization-imports qt6-quick3d-imports qt6-quick3dphysics-imports \
	qt6-3d-imports qt6-quicktimeline-imports qt6-lottie-imports \
	kf6-kimageformats libQt6Svg6 kquickimageeditor6-imports

printf '[Service]
ExecStart=
ExecStart=-/sbin/agetty -l /usr/local/bin/login --skip-login %I $TERM
' > /etc/systemd/system/getty@tty1.service.d/login.conf

chown 1000:1000 /home
chmod 700 /home

# eudev: when creating /dev/dri devices, set "render" as their group (instead of "video")
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/15409

touch /home/.config/rc-services
chown 1000:1000 /home/.config/rc-services
echo "dbus\npipewire\nwireplumber" >> /home/.config/rc-services

printf '#!/usr/bin/env sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
export LANG="en_US.UTF-8"
export MUSL_LOCPATH="/usr/share/i18n/locales/musl"
export HOME="/home"
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export WAYLAND_DISPLAY="wayland-0"
rm -rf /run/user/1000
mkdir -p /run/user/1000
chown 1000:1000 /run/user/1000
chmod 700 /run/user/1000
cat /home/.config/rc-services | while read service; do
	setpriv --reuid=1000 --regid=1000 --groups=video,audio,netdev rc-service --user "$service" restart
done
setpriv --reuid=1000 --regid=1000 --groups=input,render,video,audio,netdev --inh-caps=-all codev-shell
' > /usr/local/bin/login
chmod +x /usr/local/bin/login

printf '
' > /usr/local/share/zsh/.zprofile

printf 'autoload -Uz compinit promptinit
compinit
promptinit
prompt walters
' > /usr/local/share/zsh/.zshrc

printf '#!/usr/bin/env sh
dbus-run-session quickshell || {
	# ask user for lockscreen password and check it:
	doas -u 1000 true && bash --norc
	# to prevent BadUSB, lock when a new input device is connected
}
' > /usr/local/bin/shell
chmod +x /usr/local/bin/shell

printf '#!/apps/env sh
set -e
if [ "$1" = set ]; then
	tz="$2"
	[ -f /usr/share/zoneinfo/"$tz" ] &&
		ln -s /usr/share/zoneinfo/"$tz" /etc/localtime
elif [ "$1" = continents ]; then
	ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5
elif [ "$1" = cities ]; then
	ls -1 /usr/share/zoneinfo/"$2"/* | cut -d / -f6
elif [ "$1" = check ]; then
	# get timezone from location
	# https://www.freedesktop.org/software/geoclue/docs/gdbus-org.freedesktop.GeoClue2.Location.html
	# https://github.com/evansiroky/timezone-boundary-builder (releases -> timezone-with-oceans-now.geojson.zip)
	# https://github.com/BertoldVdb/ZoneDetect
	# tz set "$continent/$city"
else
	echo "usage:"
	echo "	tz set <continent/city>"
	echo "	tz continents"
	echo "	tz cities <continent>"
	echo "	tz check"
fi
' > /usr/local/bin/tz
chmod +x /usr/local/bin/tz
# doas rule

echo '#!/bin/sh
tz check
' > /etc/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /etc/NetworkManager/dispatcher.d/09-dispatch-script
# https://wiki.archlinux.org/title/NetworkManager#Network_services_with_NetworkManager_dispatcher

# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
# spm list ...
# spm install ...
# spm remove ...
# spm update
# spm new
' > /usr/local/bin/spm
# doas rules for "spm new"

# cp this script to /usr/local/bin/spm-new

# apk-autoupdate
# autoupdate service
# service timer: 5min after boot, every 24h
printf '#!/usr/bin/env sh
metered_connection() {
	#nmcli --terse --fields GENERAL.METERED dev show | grep --quiet "yes"
	#dbus: org.freedesktop.NetworkManager Metered
}
metered_connection && exit 0
# if plugged
# inhibit suspend/shutdown when an upgrade is in progress
# if during autoupdate an error occures: echo error > /var/cache/autoupdate-status
' > /usr/local/bin/autoupdate
chmod +x /usr/local/bin/autoupdate

printf '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
	<alias>
		<family>sans</family>
		<prefer>
			<family>Noto Sans</family>
			<family>Noto Sans Arabic</family>
		</prefer>
	</alias>
	<alias>
		<family>sans-serif</family>
		<prefer>
			<family>Noto Sans</family>
			<family>Noto Sans Arabic</family>
		</prefer>
	</alias>
	<alias>
		<family>serif</family>
		<prefer>
			<family>Noto Serif</family>
			<family>Noto Sans Arabic</family>
		</prefer>
	</alias>
	<alias>
		<family>monospace</family>
		<prefer><family>Hack</family></prefer>
	</alias>
</fontconfig>
' > /etc/fonts/local.conf

# set root password
# chroot /mnt passwd

echo; echo -n "installation completed successfully"
echo "press any key to reboot to the installed system"
read -rsn1
reboot
