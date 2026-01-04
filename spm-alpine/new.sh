# install a minimal Alpine Linux system that runs Codev inside CodevShell
# https://gitlab.alpinelinux.org/alpine/alpine-conf
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/alpine-baselayout
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/openrc
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/busybox

script_dir="$(dirname "$(realpath "$0")")"

setup-interfaces -r
ntpd -qnN -p pool.ntp.org
rc-service --quiet seedrng start

# setup a storage device for installing the new system
apk add cryptsetup btrfs-progs
new_root="$(mktemp -d)"
unmount_all="umount -q \"$new_root\"/boot; umount -q \"$new_root\"/usr; \
	umount -q \"$new_root\"/dev; umount -q \"$new_root\"/proc; \
	umount -q \"$new_root\"; rmdir \"$new_root\""
trap "trap - EXIT; $unmount_all" EXIT INT TERM QUIT HUP PIPE
sh "$script_dir"/../codev-shell/sd.sh mksys usr0 "$new_root" || exit 1

mkdir -p "$new_root"/dev "$new_root"/proc
mount --bind /dev "$new_root"/dev
mount --bind /proc "$new_root"/proc

mkdir -p "$new_root"/usr/bin "$new_root"/usr/sbin "$new_root"/usr/lib
ln -s usr/bin usr/sbin usr/lib var/etc "$new_root"/

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
	if [ "$1" = --nu ]; then
		local service="$2"
		local runlevel="$3"
		[ -z "$service" ] && return
		[ -z "$runlevel" ] && runlevel=sysinit
		ln -s /etc/user/init.d/"$service" "$new_root"/nu/.config/rc/runlevels/"$runlevel"/
	else
		local service="$1"
		local runlevel="$2"
		[ -z "$service" ] && return
		[ -z "$runlevel" ] && runlevel=default
		ln -s /etc/init.d/"$service" "$new_root"/etc/runlevels/"$runlevel"/
	fi
}

apk_new alpine-base
rc_new devfs sysinit
rc_new dmesg sysinit
rc_new bootmisc boot
rc_new hostname boot
rc_new hwclock boot
rc_new modules boot
rc_new seedrng boot
rc_new sysctl boot
rc_new syslog boot # in busybox
rc_new cgroups
rc_new savecache shutdown
rc_new killprocs shutdown
rc_new mount-ro shutdown

apk_new eudev eudev-netifnames earlyoom acpid zzz bluez \
	networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq chrony dcron
rc_new udev sysinit
rc_new udev-trigger sysinit
rc_new udev-settle sysinit
rc_new udev-postmount
rc_new earlyoom
rc_new acpid
rc_new bluetooth
rc_new networkmanager
rc_new networkmanager-dispatcher
rc_new dcron

cp -r "$script_dir"/../codev-util "$new_root"/usr/local/share/

chmod +x "$new_root"/usr/local/share/codev-util/timesync.sh
ln -s /usr/local/share/codev-util/timesync.sh "$new_root"/usr/local/bin/timesync
echo '@daily ID=timesync timesync
@reboot timesync reboot
' > "$new_root"/etc/cron.d/timesync

mkdir -p "$new_root"/usr/local/share/spm
cp -r "$script_dir"/* "$new_root"/usr/local/share/spm/
chmod +x "$new_root"/usr/local/share/spm/spm.sh
ln -s /usr/local/share/spm/spm.sh "$new_root"/usr/local/bin/spm
echo 'permit nopass nu cmd /usr/local/bin/spm' > "$new_root"/etc/doas.d/spm.conf

chmod +x "$new_root"/usr/local/share/codev-util/spm-autoup.sh
ln -s /usr/local/share/codev-util/spm-autoup.sh "$new_root"/usr/local/bin/spm-autoup
echo '@daily ID=autoupdate spm-autoup' > "$new_root"/etc/cron.d/spm-autoup

########
# boot #
########

chmod +x "$new_root"/usr/local/share/codev-util/spm-bootup.sh
ln -s /usr/local/share/codev-util/spm-bootup.sh "$new_root"/usr/local/bin/spm-bootup

chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey
echo '/usr/bin/tpm2_nvread
/usr/local/bin/tpm-getkey
' > "$new_root"/usr/local/share/mkinitfs/features/tpm.files

echo "disable_trigger=yes" > "$new_root"/etc/mkinitfs/mkinitfs.conf

apk_new linux-stable systemd-boot mkinitfs btrfs-progs cryptsetup tpm2-tools
case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && apk_new amd-ucode
	[ "$cpu_vendor_id" = GenuineIntel ] && apk_new intel-ucode
;;
esac

chroot "$new_usr" /usr/local/bin/spm-bootup /usr0

########
# user #
########

echo; echo "set root password (can be the same one entered before, to encrypt the root partition)"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

# create a normal user
chroot "$new_root" adduser --empty-password --home /nu --shell /usr/local/bin/codev-shell nu

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done

sed 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab > "$new_root"/etc/inittab.tmp
sed 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab.tmp > "$new_root"/etc/inittab

printf '#!/usr/bin/env sh
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304
exec login -f nu
' > "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/bin/autologin

###############
# codev-shell #
###############

if apk info quickshell &>/dev/null; then
	apk_new quickshell --virtual .quickshell
else
	apk_new git clang cmake ninja-is-really-ninja pkgconf spirv-tools wayland-protocols qt6-qtshadertools-dev \
		jemalloc-dev pipewire-dev libdrm-dev mesa-dev wayland-dev \
		qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtsvg-dev qt6-qtwayland-dev --virtual .quickshell
		chroot "$new_root" sh "$script_dir"/spm.sh quickshell
fi
apk_new setpriv doas-sudo-shim musl-locales tzdata geoclue bash bash-completion dbus \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware \
	mesa-dri-gallium mesa-va-gallium breeze breeze-icons \
	font-adobe-source-code-pro font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	qt6-qtvirtualkeyboard qt6-qtsensors mauikit-terminal .quickshell --virtual .codev-shell
rc_new dbus
rc_new --nu dbus
rc_new --nu pipewire
rc_new --nu wireplumber

cp -r "$script_dir"/../codev-shell "$new_root"/usr/local/share/codev-shell
chmod +x "$new_root"/usr/local/share/codev-shell/codev-shell.sh
ln -s "$new_root"/usr/local/share/codev-shell/codev-shell.sh "$new_root"/usr/local/bin/codev-shell

mkdir -p "$new_root"/etc/doas.d
cat <<-EOF > "$new_root"/etc/doas.d/codev-shell.conf
permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,video,audio /usr/local/bin/codev-shell priv
permit nopass nu cmd /usr/bin/passwd nu
EOF

chmod +x "$new_root"/usr/local/share/codev-shell/system.sh
ln -s /usr/local/share/codev-shell/system.sh "$new_root"/usr/local/bin/system

chmod +x "$new_root"/usr/local/share/codev-shell/sd.sh
ln -s /usr/local/share/codev-shell/sd.sh "$new_root"/usr/local/bin/sd
echo 'permit nopass nu cmd /usr/local/bin/sd' > "$new_root"/etc/doas.d/sd.conf

echo '#!/bin/sh
case "$2" in
up) sudo -u nu system tz guess ;;
esac
' > /etc/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /etc/NetworkManager/dispatcher.d/09-dispatch-script

#########
# codev #
#########

apk_new mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-documents \
	kio-extras kimageformats qt6-qtsvg \
	qt6-qtmultimedia ffmpeg-libavcodec qt6-qtwebengine qt6-qtlocation geoclue qt6-qtremoteobjects qt6-qtspeech \
	qt6-qtcharts qt6-qtgraphs qt6-qtdatavis3d qt6-qtquick3d qt6-qt3d qt6-qtquicktimeline \
	gnunet aria2 openssh --virtual .codev
# qt6-qtquick3dphysics qt6-qtlottie
cp -r "$script_dir"/../codev "$new_root"/usr/local/share/
mkdir -p "$new_root"/usr/local/share/icons/hicolor/scalable/apps
cp "$script_dir"/../.data/codev.svg "$new_root"/usr/local/share/icons/hicolor/scalable/apps/

mkdir -p "$new_root"/usr/local/share/applications
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
