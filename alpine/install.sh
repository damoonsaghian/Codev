set -e

# https://wiki.alpinelinux.org/wiki/Installation
# https://gitlab.alpinelinux.org/alpine/alpine-conf

# https://github.com/davmac314/dinit
# https://github.com/davmac314/dinit/blob/master/doc/getting_started.md
# https://davmac.org/projects/dinit/man-pages-html/dinit.8.html
# https://davmac.org/projects/dinit/man-pages-html/dinit-service.5.html
# https://davmac.org/projects/dinit/alpine-demo/
# https://github.com/ndowens/alpine-dinit-scripts
# https://github.com/mohamad-supangat/dinit.d
# https://wiki.artixlinux.org/Main/dinit
# https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/openrc
# https://pkgs.alpinelinux.org/package/edge/main/x86_64/alpine-base

# ask if the user wants to install a new system, or fix an existing system
# apk fix --root /mnt

lock_grub() {
	# since we will lock root, recovery entries are useless
	printf '\nGRUB_DISABLE_RECOVERY=true\nGRUB_DISABLE_OS_PROBER=true\nGRUB_TIMEOUT=0\n' >> /etc/default/grub
	# disable menu editing and other admin operations in Grub:
	cat <<-'__EOF__' > /etc/grub.d/09_user
	#! /bin/sh
	set superusers=""
	set menuentry_id_option="--unrestricted $menuentry_id_option"
	__EOF__
	chmod +x /etc/grub.d/09_user
	grub-mkconfig -o /boot/grub/grub.cfg
}
[ grub is installed ] && lock_grub

<<#
despite using BTRFS, in-place writing is needed in two situations:
, in-place first write for preallocated space, like in torrents
	we don't want to disable COW for these files
	apparently supported by BTRFS, isn't it?
	https://lore.kernel.org/linux-btrfs/20210213001649.GI32440@hungrycats.org/
	https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
	https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3
, virtual machines and databases (eg the one used in Webkit)
	COW must be disabled for these files
	generally it's done automatically by the program itself (eg systemd-journald)
	otherwise we must do it manually: chattr +C ...
	apparently Webkit uses SQLite in WAL mode
#

apk add alpine-base linux-lts
[  ] && apk add intel-ucode
[  ] && apk add amd-ucode

apk add doas wget2 py3-gobject3

# https://wiki.alpinelinux.org/wiki/PipeWire
apt-get install --no-install-recommends --yes wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
	cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

# ask the user to provide different passwords for root and for the user

groupadd su
adduser user1 -G netdev

cat <<'__EOF__' > /usr/local/share/su-chkpasswd.sh
set -e
root_passwd_hashed="$(sed -n '/root/p' /etc/shadow | cut -d ':' -f2)"
hash_method="$(echo "$root_passwd_hashed" | cut -d '$' -f2)"
case "$hashtype" in
	1) hashtype=md5 ;;
	5) hashtype=sha-256 ;;
	6) hashtype=sha-512 ;;
	*) echo "error: password hash type is unsupported"; exit 1 ;;
esac
salt="$(echo $root_passwd_hashed | cut -d '$' -f3)"
printf "enter root password: "
IFS= read -rs entered_passwd
entered_passwd_hashed="$(echo "$entered_passwd" | cryptpw -s --method="$hash_method" --salt="$salt")"
if [ "$entered_passwd_hashed" = "$root_passwd_hashed" ]; then
  exit 0
else
  exit 1
fi
__EOF__

echo -n '#!doas /bin/sh
set -e
# switch to the first available virtual terminal and ask for root password,
#   and if successful, run the given command
if openvt -sw -- /bin/sh /usr/localshare/su-chkpasswd.sh "$@"; then
	$@
else
	echo "authentication failure"
fi
' > /usr/local/bin/su
chmod +x /usr/local/bin/su

echo 'permit nopass :su cmd /bin/sh args /usr/local/bin/su' >> /etc/doas.conf
# lock root account
passwd --lock root

# guess time'zone but let the user to confirm it
# wget -q -O- http://ip-api.com/line/?fields=timezone)

echo -n '#!doas /bin/sh
read timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
' > /usr/local/bin/tzset
chmod +x /usr/local/bin/tzset
echo 'permit nopass :users cmd /bin/sh args /usr/local/bin/tzset' >> /etc/doas.conf

apk add connman iwd wireless-regdb ofono bluez
cp /mnt/comshell/di/system /usr/local/bin/
chmod +x /usr/local/bin/system
# connman service files:
# https://git.alpinelinux.org/aports/tree/community/connman

cp /mnt/comshell/di/system-packages /usr/local/bin/
chmod +x /usr/local/bin/system-packages
echo 'permit nopass :su cmd /bin/sh args /usr/local/bin/system-packages' >> /etc/doas.conf

# cronjob for automatic update
# /usr/local/bin/system-packages autoupdate
# OnBootSec=5min
# OnUnitInactiveSec=24h
# RandomizedDelaySec=5min

# install the corresponding firmwares when new hardware is inserted into the machine
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/system-packages install-firmware %k"' >
	/etc/udev/rules.d/80-install-firmware.rules

echo -n 'PS1="\e[7m\u@\h:\w\e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

cp /mnt/comshell/os/sd.sh /usr/local/bin/sd
chmod +x /usr/local/bin/sd
echo 'permit nopass :users cmd /bin/sh args /usr/local/bin/sd' >> /etc/doas.conf

apk add sway swayidle swaylock xwayland psmisc fuzzel foot font-hack font-noto

# https://wiki.alpinelinux.org/wiki/Sway

# https://codeberg.org/dnkl/fuzzel

# alternatives:
# tofi
# https://github.com/ii8/havoc

cp /mnt/comshell/di/{sway.conf,sway-status.py} /usr/local/share/

mkdir -p /etc/fonts
echo -n '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
	<alias>
		<family>serif</family>
		<prefer><family>NotoSerif</family></prefer>
	</alias>
	<alias>
		<family>sans</family>
		<prefer><family>NotoSans</family></prefer>
	</alias>
	<alias>
		<family>monospace</family>
		<prefer><family>Hack</family></prefer>
	</alias>
</fontconfig>
' > /etc/fonts/local.conf

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don’t have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# "https://input.djr.com/"

echo -n '[Desktop Entry]
Type=Application
Name=Terminal
Exec=footclient
StartupNotify=true
' > /usr/local/share/applications/terminal.desktop
echo -n '[Desktop Entry]
NoDisplay=true
' | tee /usr/local/share/applications/{foot,footclient,foot-server}.desktop
echo -n 'font=monospace:size=10.5
[scrollback]
indicator-position=none
[cursor]
blink=yes
[colors]
background=f8f8f8
foreground=2A2B32
selection-foreground=f8f8f8
selection-background=2A2B32
regular0=20201d  # black
regular1=d73737  # red
regular2=60ac39  # green
regular3=cfb017  # yellow
regular4=6684e1  # blue
regular5=b854d4  # magenta
regular6=1fad83  # cyan
regular7=fefbec  # white
bright0=7d7a68
bright1=d73737
bright2=60ac39
bright3=cfb017
bright4=6684e1
bright5=b854d4
bright6=1fad83
bright7=fefbec
' > /usr/local/share/foot.cfg

echo -n 'history = false
require-match = true
drun-launch = false
font = monospace
background-color = #000A
prompt-text = ""
width = 100%
height = 100%
border-width = 0
outline-width = 0
padding-left = 35%
padding-right = 35%
padding-top = 20%
padding-bottom = 20%
result-spacing = 25
' > /usr/local/share/tofi.cfg

echo -n 'PS1="\e[7m\u@\h:\w\e[0m\n> "
# run sway (if this script is not called by a display manager)
elif [ -z $DISPLAY ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zzz.sh

apk add openssh-client-default attr
cp /mnt/comshell/di/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

apk add gtk4.0 gtksourceview5 webkit2gtk-5.0 poppler-glib vte3-gtk4 gst-plugins-good gst-libav \
	libarchive-tools exfatprogs btrfs-progs
# heif-gdk-pixbuf
cp -r /mnt/comshell/comshell-py /usr/local/share/
mkdir -p /usr/local/share/applications
echo -n '[Desktop Entry]
Type=Application
Name=Comshell
Exec=sh -c "swaymsg workspace 1:comshell; comshell || python3 /usr/local/share/comshell-py/"
StartupNotify=true
' > /usr/local/share/applications/comshell.desktop
