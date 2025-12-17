# install a minimal Alpine Linux system that runs Codev inside CodevShell
# https://gitlab.alpinelinux.org/alpine/alpine-conf
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/alpine-baselayout
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/openrc
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/busybox

script_dir="$(dirname "$(realpath "$0")")"

if [ $(id -u) != 0 ]; then
	echo "this script must be run as root"
	exit 1
fi

setup-interfaces -r
ntpd -qnN -p pool.ntp.org
rc-service --quiet seedrng start

# setup a storage device to install the new system
apk add cryptsetup btrfs-progs
{ sh "$script_dir"/../codev-util/sd.sh mksys || exit 1; } | {
	read -r boot_mountopt
	read -r boot_uuid
	read -r cryptroot_uuid
	read -r new_root
}
unmount_all="umount \"$new_root\"/boot; umount \"$new_root\"/var; umount \"$new_root\"/home; \
	umount -q \"$new_root\"/dev; umount -q \"$new_root\"/proc; \
	umount \"$new_root\"; rmdir \"$new_root\""
trap "trap - EXIT; $unmount_all" EXIT INT TERM QUIT HUP PIPE

mkdir -p "$new_root"/dev
mkdir -p "$new_root"/proc
mount --bind /dev "$new_root"/dev
mount --bind /proc "$new_root"/proc

mkdir -p "$new_root"/var/etc
ln --symbolic var/etc "$new_root"/

mkdir -p "$new_root"/usr/lib "$new_root"/usr/bin "$new_root"/usr/sbin
ln --symbolic usr/bin usr/sbin usr/lib "$new_root"/

printf "UUID=$boot_uuid /boot vfat ${boot_mountopt}rw,noatime 0 0
/dev/mapper/rootfs /var btrfs subvol=/var,rw,noatime 0 0
/dev/mapper/rootfs /home btrfs subvol=/home,rw,noatime 0 0
" > "$new_root"/var/etc/fstab

mkdir -p "$new_root"/etc/apk/keys/
cp /etc/apk/keys/* "$new_root"/etc/apk/keys/

mkdir -p "$new_root"/etc/apk
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing
' > "$new_root"/etc/apk/repositories

apk_new() {
	apk --repositories-file "$new_root"/etc/apk/repositories --root "$new_root" --quiet --progress add $@
}

rc_new() {
	if [ "$1" = --user ] || [ "$1" = -u ]; then
		local service="$2"
		local runlevel="$3"
		[ -z "$service" ] && return
		[ -z "$runlevel" ] && runlevel=sysinit
		ln --symbolic /etc/user/init.d/"$service" "$new_root"/home/.config/rc/runlevels/"$runlevel"/
	else
		local service="$1"
		local runlevel="$2"
		[ -z "$service" ] && return
		[ -z "$runlevel" ] && runlevel=default
		ln --symbolic /etc/init.d/"$service" "$new_root"/etc/runlevels/"$runlevel"/
	fi
}

. "$script_dir"/new-boot.sh
. "$script_dir"/new-base.sh
. "$script_dir"/new-netman.sh

quickshell_pkg=
apk info quickshell &>/dev/null && quickshell_pkg=quickshell
apk_new doas-sudo-shim bash bash-completion mesa-dri-gallium mesa-va-gallium breeze breeze-icons \
	font-adobe-source-code-pro font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	qt6-qtvirtualkeyboard qt6-qtsensors mauikit-terminal $quickshell_pkg --virtual codev-shell
[ -z $quickshell_pkg ] && {
	apk_new add git clang cmake ninja-is-really-ninja pkgconf spirv-tools wayland-protocols qt6-qtshadertools-dev \
		jemalloc-dev pipewire-dev libdrm-dev mesa-dev wayland-dev \
		qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtsvg-dev qt6-qtwayland-dev --virtual quickshell-git
	chroot "$new_root" sh "$script_dir"/spm-apk.sh update
}
cp -r "$script_dir"/../codev-shell "$new_root"/usr/local/share/codev-shell
chmod +x "$new_root"/usr/local/share/codev-shell/codev-shell.sh
ln -s "$new_root"/usr/local/share/codev-shell/codev-shell.sh "$new_root"/usr/local/bin/codev-shell

mkdir -p "$new_root"/etc/doas.d
cat <<-EOF > "$new_root"/etc/doas.d/codev-shell.conf
permit nopass home cmd setpriv --reuid=home --regid=home --groups=input,video,audio /usr/local/bin/codev-shell
permit nopass home cmd /usr/bin/passwd home
EOF

echo '#!/usr/bin/env sh
openrc -U
' > "$new_root"/usr/local/bin/home-services
chmod +x "$new_root"/usr/local/bin/home-services

cp -r "$script_dir"/../codev-util "$new_root"/usr/local/share/
cp "$script_dir"/spm-apk.sh /usr/local/bin/spm
chmod +x /usr/local/bin/spm
cat <<-EOF > "$new_root"/etc/doas.d/codev-util.conf
permit nopass home cmd sh /usr/local/share/codev-util/sd.sh
permit nopass home cmd /usr/local/bin/spm
EOF

apk_new mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-documents \
	kio-extras kimageformats qt6-qtsvg \
	qt6-qtmultimedia ffmpeg-libavcodec qt6-qtwebengine gnunet aria2 openssh \
	qt6-qtlocation qt6-qtremoteobjects qt6-qtspeech \
	qt6-qtcharts qt6-qtgraphs qt6-qtdatavis3d qt6-qtquick3d qt6-qt3d qt6-qtquicktimeline --virtual codev
# qt6-qtquick3dphysics qt6-qtlottie
cp -r "$script_dir"/../codev "$new_root"/usr/local/share/
cp "$script_dir"/../.data/codev.svg "$new_root"/usr/local/share/icons/hicolor/scalable/apps/
echo '[Desktop Entry]
Name=Codev
Comment=Collaborative Development
Icon=codev
exec=qml6 /usr/local/share/codev/main.qml
StartupNotify=true
Type=Application
' > "$new_root"/usr/local/share/applications/codev.desktop

echo; echo -n "installation completed successfully"
echo "press any key to reboot the system"
read -rsn1
reboot
