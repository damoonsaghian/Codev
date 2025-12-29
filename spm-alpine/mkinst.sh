# create a bootable installer on a removable storage device

script_dir="$(dirname "$(realpath "$0")")"

cd "$script_dir"/../.cache/spm-alpine

mkdir -p target iso_mount
ovl_dir="$(mktemp -d)"
trap "trap - EXIT; umount -q target; umount -q iso_mount; rmdir target iso_mount; rm -r \"$ovl_dir\"" \
	EXIT INT TERM QUIT HUP PIPE

printf 'installation media can be made for these architectures:
	1) x86_64
	2) aarch64
	3) riscv64
'
echo "enter the number of the desired architechture: "
read -r ans
case "$ans" in
1) arch=x86_64 ;;
2) arch=aarch64 ;;
3) arch=riscv64 ;;
esac

# download iso (using curl or wget)
release_info_url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$arch/latest-releases.yaml"
if command -v curl; then
	curl "$release_info_url"
	# grep "file: alpine-standared-.*" | grep -o "alpine-standared-.*"
elif command -v wget; then
	wget "$release_info_url"
	# grep "file: alpine-standared-.*" | grep -o "alpine-standared-.*"
else
	echo 'either "curl" or "wget" must be installed on the system'
	exit 1
fi
mount "$alpine_iso_file_name" iso_mount
cp -r iso_mount/* target/

sh "$script_dir"/../codev-shell/sd.sh format-inst target || exit 1

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

rm -f localhost.apkovl.tar.gz
tar --owner=0 --group=0 -czf localhost.apkovl.tar.gz "$ovl_dir"
mv localhost.apkovl.tar.gz "$targte_dir"/

echo "bootable installer successfully created"
