script_dir="$(dirname "$(realpath "$0")")"

ovl_dir="$script_dir"/../.cache/alpine/ovl
rm -r "$ovl_dir"
mkdir -p "$ovl_dir"

# this is necessary when using an overlay
mkdir -p "$ovl_dir"/etc
touch "$ovl_dir"/etc/.default_boot_services

mkdir -p "$ovl_dir"/codev
cp -r "$script_dir"/../alpine "$ovl_dir"/codev/
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
