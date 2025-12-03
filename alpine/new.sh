# install a minimal Alpine Linux system that runs Codev inside CodevShell
# https://gitlab.alpinelinux.org/alpine/alpine-conf
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/alpine-baselayout
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/busybox
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/openrc

script_dir="$(dirname "$(realpath "$0")")"

if [ $(id -u) != 0 ]; then
	echo "this script must be run as root"
	exit 1
fi

setup-interfaces -r
ntpd -qnN -p pool.ntp.org
rc-service --quiet seedrng start

# setup a storage device for the new system
apk add cryptsetup btrfs-progs
{ sh "$script_dir"/../codev-util/sd.sh mksys || exit 1 } | {
	read -r boot_mountopt
	read -r boot_uuid
	read -r cryptroot_uuid
	read -r new_root
}

mkdir -p "$new_root"/var/etc
ln --symbolic --relative "$new_root"/var/etc "$new_root"/etc

printf "UUID=$boot_uuid /boot vfat ${boot_mountopt}rw,noatime 0 0
/dev/mapper/rootfs /var btrfs subvol=/var,rw,noatime 0 0
/dev/mapper/rootfs /home btrfs subvol=/home,rw,noatime 0 0
" > "$new_root"/etc/fstab

mkdir -p "$new_root"/etc/apk
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing
' > "$new_root"/etc/apk/repositories

apk_new() {
	apk --repositories-file "$new_root"/etc/apk/repositories --root "$new_root" --quiet $@
}

rc_new() {
	local service="$2"
	local runlevel="$3"
	[ -z "$service" ] && return
	[ -z "$runlevel" ] && runlevel=default
	case "$1" in
	add) ln --symbolic --relative "$new_root"/etc/init.d/"$service" "$new_root"/etc/runlevels/"$runlevel"/ ;;
	del|delete) rm -f "$new_root"/etc/runlevels/"$runlevel"/"$service" ;;
	esac
}

. "$script_dir"/setup-boot.sh
. "$script_dir"/setup-base.sh
. "$script_dir"/setup-pm.sh
. "$script_dir"/setup-netman.sh
. "$script_dir"/setup-codev.sh

echo; echo -n "installation completed successfully"
echo "press any key to reboot the system"
read -rsn1
reboot
