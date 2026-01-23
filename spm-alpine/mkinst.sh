# create a bootable installer on a removable storage device

# name of the target device to write the installer on
# it's an optional argument
# if empty, this script will be interactive, and will allow the user to choose the target device
target_device="$1"

script_dir="$(dirname "$(readlink -f "$0")")"

wdir="$HOME"/.cache/spm-alpine
cd "$wdir"

mkdir -p target iso_mount
ovl_dir="$(mktemp -d)"
trap "trap - EXIT; umount -q target; umount -q iso_mount; rmdir target iso_mount; rm -r \"$ovl_dir\"" \
	EXIT INT TERM QUIT HUP PIPE

mkdir -p "$ovl_dir"/codev
cp -r "$script_dir"/../spm-alpine "$ovl_dir"/codev/
cp -r "$script_dir"/../codev "$ovl_dir"/codev/
cp -r "$script_dir"/../codev-shell "$ovl_dir"/codev/
cp -r "$script_dir"/../codev-util "$ovl_dir"/codev/
if [ -d "$script_dir"/../.data]; then
	cp -r "$script_dir"/../.data "$ovl_dir"/codev/
else
	cp -r "$script_dir"/../icons/hicolor/scalable/apps/codev.svg "$ovl_dir"/codev/.data/
fi

mkdir -p "$ovl_dir"/root
printf 'sh /codev/alpine/new.sh
' > "$ovl_dir"/root/.profile

printf '#!/usr/bin/env sh
exec login -f root
' > "$ovl_dir"/usr/local/bin/autologin
chmod +x "$ovl_dir"/usr/local/bin/autologin

mkdir -p "$ovl_dir"/etc
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

# this is necessary when using an overlay
touch "$ovl_dir"/etc/.default_boot_services

rm -f localhost.apkovl.tar.gz
tar --owner=0 --group=0 -czf localhost.apkovl.tar.gz "$ovl_dir"

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

# try previously downloaded file from cache, and exit if there is none
try_cached_alpine_iso() {
	alpine_iso_file_name=$(ls alpine-standard-*-"$arch".iso | tail -n1)
	sha256sum "$alpine_iso_file_name" || {
		rm -f "$alpine_iso_file_name"
		echo "downloaded file was corrupted; try again"
		exit 1
	}
	if [ -e "$alpine_iso_file_name" ]; then
		echo "using previousely downloaded file: '$wdir/$alpine_iso_file_name'"
	else
		echo "alternatively, download an standard image from https://alpinelinux.org/downloads/,"
		echo "	and put it in '$wdir'"
		exit 1
	fi
}

download_url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$arch"
if command -v curl; then
	if curl --proto '=https' -fO "$download_url/latest-releases.yaml"; then
		alpine_iso_file_name="$(cat latest-releases.yaml | grep "file: alpine-standared-.*")"
		alpine_iso_file_name="$(echo "$alpine_iso_file_name" | cut -d: -f2 | tr -d "[:blank:]")"
		curl --proto '=https' -fO -C- "$download_url/$alpine_iso_file_name"
		curl --proto '=https' -fO  "$download_url/$alpine_iso_file_name.sha256"
		sha256sum "$alpine_iso_file_name" || {
			rm -f "$alpine_iso_file_name"
			echo "downloaded file was corrupted; try again"
			exit 1
		}
	else
		echo "can't reach Alpine Linux server"
		try_cached_alpine_iso
	fi
elif command -v wget; then
	rm -f latest-releases.yaml
	if wget --no-verbose "$download_url/latest-releases.yaml"; then
		alpine_iso_file_name="$(cat latest-releases.yaml | grep "file: alpine-standared-.*")"
		alpine_iso_file_name="$(echo "$alpine_iso_file_name" | cut -d: -f2 | tr -d "[:blank:]")"
		wget --no-verbose --show-progress --no-clobber "$download_url/$alpine_iso_file_name"
		rm -f "$alpine_iso_file_name.sha256"
		wget --no-verbose "$download_url/$alpine_iso_file_name.sha256"
		sha256sum "$alpine_iso_file_name" || {
			rm -f "$alpine_iso_file_name"
			echo "downloaded file was corrupted; try again"
			exit 1
		}
	else
		echo "can't reach Alpine Linux server"
		try_cached_alpine_iso
	fi
else
	echo "can't download Alpine Linux installer image; since neither \"curl\" nor \"wget\" is available"
	try_cached_alpine_iso
fi
mount "$alpine_iso_file_name" iso_mount

# prepare a storage device, and copy the files into it
sh "$script_dir"/../codev-shell/sd.sh format-inst "$wdir/target" "$target_device" || exit
cp -r iso_mount/* target/
mv localhost.apkovl.tar.gz target/

echo "bootable installer successfully created"
