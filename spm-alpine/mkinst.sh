# create an installer on a removable storage device

script_dir="$(dirname "$(realpath "$0")")"

target_device="$(sh "$script_dir"/../codev-shell/sd.sh format-inst)"

target_dir="$(mktemp -d)"
trap "trap - EXIT; umount -q \"$target_dir\"; rmdir \"$target_dir\"" EXIT INT TERM QUIT HUP PIPE
mount "$target_device" "$target_dir"

# ask user to choose a target architecture

# download iso (using curl or wget) https://alpinelinux.org/downloads/
# mount it and copy its content into $target_dir

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
mv "$script_dir"/../.cache/alpine/localhost.apkovl.tar.gz "$targte_dir"/

rm -r "$ovl_dir"
