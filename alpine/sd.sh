#!doas /bin/sh
set -e

format() {
	# if the device is not removable exit
	# format with VFAT (or exFAT if there would be files bigger than 4GB)
	mkfs.vfat /dev/"$1"
}

mount() {
	[ if not removable ] && {
		mkdir -p /run/mount/"$1"
		result=$"(findmnt --mountpoint /run/mount/"$1")"
		
		[ -z "$result" ] && mount -o nosuid,nodev,noexec,nofail /dev/$1 /run/mount/"$1"
		cp --no-clobber --preserve=all /home/ /run/mount/"$1"
	}
	
	$DOAS_USER
	mkdir -p /run/mount/"$1"
	result=$"(findmnt --mountpoint /run/mount/"$1")"
	[ -z "$result" ] && mount -o gid=,uid= /dev/"$1" /run/mount/"$1"
}

unmount() {
	umount /run/mount/$1
}

write() {}
