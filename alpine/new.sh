# install a minimal Alpine Linux system that runs Codev inside CodevShell
# https://gitlab.alpinelinux.org/alpine
# https://gitlab.alpinelinux.org/alpine/alpine-conf
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/alpine-baselayout
# https://docs.alpinelinux.org/
# https://wiki.alpinelinux.org/wiki/Daily_driver_guide
# https://wiki.alpinelinux.org/wiki/Developer_Documentation

script_dir="$(dirname "$(realpath "$0")")"

if [ $(id -u) != 0 ]; then
	echo "this script must be run as root"
	exit 1
fi

setup-interfaces -r

apk add cryptsetup btrfs-progs
sh "$script_dir"/../codev-util/sd-new-sys.sh | {
	read -r new_root
	read -r cryptroot_uuid
	read -r root_uuid
}

mkdir -p "$new_root"/etc/apk
echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing
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
	add) ln -s "$new_root"/etc/init.d/"$service" "$new_root"/etc/runlevels/"$runlevel"/ ;;
	del|delete) rm -f "$new_root"/etc/runlevels/"$runlevel"/"$service" ;;
	esac
}

. "$script_dir"/setup-boot.sh
. "$script_dir"/setup-base.sh
. "$script_dir"/setup-pm.sh
. "$script_dir"/setup-netman.sh
. "$script_dir"/setup-shell.sh

apk_new add gnunet aria2
# https://wiki.alpinelinux.org/wiki/GNUnet

apk_new add mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-terminal mauikit-documents \
	breeze breeze-icons

apk_new add qt6-multimedia-imports qt6-webengine-imports qt6-pdf-imports qt6-virtualkeyboard-imports \
	qt6-location qt6-remoteobjects-imports qt6-sensors-imports qt6-texttospeech \
	qt6-charts-imports qt6-graphs-imports qt6-datavisualization-imports qt6-quick3d-imports qt6-quick3dphysics-imports \
	qt6-3d-imports qt6-quicktimeline-imports qt6-lottie-imports \
	kf6-kimageformats libQt6Svg6 kquickimageeditor6-imports

# install codev
# /usr/local/share/codev
# .data/codev.svg
# doas rules for sd.sh
# codev executable has setgid 10 that lets it to read (password protected) private keys
# update hook for codev

echo; echo -n "installation completed successfully"
echo "press any key to reboot the system"
read -rsn1
reboot
