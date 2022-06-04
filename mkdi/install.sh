set -e

cd "$(dirname "$0")"

btrfs subvolume create /0
btrfs subvolume snapshot / /0

rm -r /0/etc/* /0/home/* /0/root/* /0/opt/* /0/usr/local/* /0/srv/* /0/var/*
rm -d /0/0

mount --bind /boot/efi /0/boot/efi

# directories which must change atomically during an upgrade
ln --symbolic --force -t / /0/bin
ln --symbolic --force -t / /0/boot
ln --symbolic --force -t / /0/lib
ln --symbolic --force -t / /0/lib64
ln --symbolic --force -t / /0/sbin
ln --symbolic --force -t / /0/usr

# for U-boot based ARM systems which need flash-kernel, implementing atomic upgrade is complicated
# furthermore, for old ARMel systems which need the kernel and initrd to be flashed in their ROM,
#   implementing atomic upgrade is impossible
# MIPS systems are not supported for a similar reason too
# also s390x is not supported because ZIPL only understands data'blocks (not the filesystem),
#   and thus must be rewritten everytime kernel/initrd is updated

# for U-boot based systems which support "generic distro configuration":
#   remove flash-kernel, make a generic bootscr, and put it in boot partition
# https://source.denx.de/u-boot/u-boot/-/blob/master/doc/develop/distro.rst
# libubootenv-tool
# https://salsa.debian.org/installer-team/flash-kernel/-/blob/master/bootscript/arm64/bootscr.uboot-generic
# in bootscr first try to load "vmlinuz.trans" and "initrd.trans"
# before upgrading create these symlinks: vmlinuz.trans initrd.trans

# if EFI, remove Grub then unified kernel image using systemd linux stub
# https://wiki.archlinux.org/title/Unified_kernel_image
# https://man.archlinux.org/man/systemd-stub.7
# https://systemd.io/BOOT_LOADER_SPECIFICATION/#type-2-efi-unified-kernel-images
# https://wiki.debian.org/EFIStub
# /EFI/BOOT/BOOTx64.EFI BOOTIA32.EFI

# otherwise disable Grub upgrade, and lock Grub
# printf '\nGRUB_TIMEOUT=0\nGRUB_DISABLE_OS_PROBER=true\n' >> /mnt/etc/default/grub
# disable menu editing and other admin operations in Grub:
# printf '#! /bin/sh\nset superusers=""\nset menuentry_id_option="--unrestricted $menuentry_id_option"\n' >
#   /mnt/etc/grub.d/09_user
# chmod +x /mnt/etc/grub.d/09_user
# update-grub
# after upgrade: grub-mkconfig

# Debian ppc64el can read btrfs /boot, cause it uses 64kB page size, just like Petitboot

# grub and bootfirmware updates need special care
# unless there is a read_only backup, firmware update is not a good idea
# fwupd

# timezone

# sid
# contrib and non-free
# no recommends

# dosfstools exfatprogs btrfs-progs udisks2 polkitd
# iwd wireless-regdb modemmanager usb-modeswitch pppoe rfkill bluez
# wireplumber pipewire-pulse pipewire-audio-client-libraries libspa-0.2-bluetooth
#   https://wiki.debian.org/PipeWire#Debian_Testing.2FUnstable
# kbd is needed for its chvt
# sway swayidle swaylock grim xwayland
# fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji materia-gtk-theme
# openssh-client wget2 attr
# libarchive-tools
# libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf
# python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18
# gdk gio and glib girs

# mono'space fonts:
#   wide characters are forced to squeeze
#   narrow characters are forced to stretch
#   uppercase letters look skinny next to lowercase
#   bold characters don’t have enough room
# proportional font for code:
#   generous spacing
#   large punctuation
#   and easily distinguishable characters
#   while allowing each character to take up the space that it needs
# "https://input.djr.com/"
# for proportional fonts, we can't use spaces for text alignment
# elastic tabstops may help: "http://nickgravgaard.com/elastic-tabstops/"
# but i think, text alignment is a bad idea, in general

# https://github.com/maximbaz/wluma
# https://github.com/FedeDP/Clight
# https://wiki.archlinux.org/title/Backlight#Backlight_utilities
# https://github.com/Ventto/lux
#   https://github.com/harttle/macbook-lighter

echo '[Match]
Type=ether
Name=! veth*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
' > /etc/systemd/network/20-wired.network
echo '[Match]
Type=wlan
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600
' > /etc/systemd/network/20-wireless.network
echo '[Match]
Type=wwan
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=700
[IPv6AcceptRA]
RouteMetric=700
' > /etc/systemd/network/20-wwan.network
systemctl enable systemd-networkd
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved
systemctl enable iwd

cp ./net /usr/local/bin/net
chmod +x /usr/local/bin/net

echo '#!/bin/sh
if [ "$1" = "disconnect" ]; then
  bluetoothctl paired-devices
  echo -n "select a device (enter the MAC address): "; read mac_address
  bluetoothctl disconnect "$mac_address"
  bluetoothctl untrust "$mac_address"
  exit
fi
bluetoothctl scan on
echo -n "select a device (enter the MAC address): "; read mac_address
if [ bluetoothctl --agent -- pair "$mac_address" ]; then
  bluetoothctl trust "$mac_address"
  bluetoothctl connect "$mac_address"
else
  bluetoothctl untrust "$mac_address"
fi
' > /usr/local/bin/bt

echo '#!/bin/sh
if [ $1 = disable ]; then
  rm /etc/systemd/system/getty@tty1.service.d/override.conf
  exit
fi
if [ $1 = enable ]; then
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  printf "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin $2 --noclear %I $TERM" >
    /etc/systemd/system/getty@tty1.service.d/override.conf
  exit
fi
echo "usage:
autologin disable
autologin enable <user>"
' > /usr/local/bin/autologin
chmod +x /usr/local/bin/autologin

echo '#!/bin/sh
# the next available virtual terminal
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
chvt "$navt"
echo "$navt" > /tmp/navt-vt
' > /usr/local/bin/navt
chmod u+s,+x /usr/local/bin/navt

# when a keyboard is connected, disable others, lock the session (if any), run "navt"
# since password prompts only accept keyboard input, this not necessary for headsets
# authentication cards (which can also be embedded in headsets) do this automatically
# this has two benefits:
# , when you want to login you are sure that it's the login screen (not a fake one created by another user)
# , others can't access your session using another keyboard

echo '# execute this script if running from tty1, or if put here by "navt"
if [ "$(tty)" = "/dev/tty1" ] || [ "$(fgconsole)" = "$(cat /tmp/navt-vt)" ]; then
  # if a user session is already running, switch to it, unlock it, and exit
  loginctl show-user "$USER" --value --property=Sessions | {
    read current_session previous_session rest
    previous_tty=$(loginctl show-session $previous_session --value --property=TTY)
    current_tty=$(tty)
    current_tty=${current_tty##*/}
    if [ -n $previous_session ] && [ $current_tty != $previous_tty ]; then
      loginctl activate $previous_session &&
      loginctl unlock-session $previous_session
      systemctl stop getty@$current_tty.service
      exit
    fi
  }
  exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/login-manager.sh

cp ./sway.conf /usr/local/share/

# create a system user named "su" with a password equal to root's password
useradd --system --password $(getent shadow root | cut -d: -f2) su
echo '#!/bin/sh
# in Wayland open a window demanding the password of "su" user
# in tty demand the password at the command line
# https://unix.stackexchange.com/questions/329878/check-users-password-with-a-shell-script
# https://unix.stackexchange.com/questions/21705/how-to-check-password-with-linux
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
' > /usr/local/bin/sudo
chgrp root /usr/local/bin/sudo
chmod u+s,ug+x /usr/local/bin/sudo
# add the first user to root group
usermod -aG root $(id -nu 1000)
# lock root
passwd -l root

cp ./sd /usr/local/bin/sd
chmod +x /usr/local/bin/sd

cp ./apm /usr/local/bin/apm
chmod +x /usr/local/bin/apm

cp ./fwi /usr/local/bin/fwi
chmod +x /usr/local/bin/fwi
# find and install required firmwares
fwi
# create a service to do it automatically in the future

mkdir -p /usr/local/lib/systemd/system
echo '[Unit]
Description=automatic update
After=network-online.target
[Service]
ExecStart=/usr/local/bin/apm autoupdate
Nice=19
KillMode=process
KillSignal=SIGINT
' > /usr/local/lib/systemd/system/autoupdate.service
echo '[Unit]
Description=automatic update timer
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/autoupdate.timer
systemctl enable autoupdate.timer

cp ./codev /usr/local/bin/codev
chmod +x /usr/local/bin/codev

mkdir -p /usr/local/lib/systemd/system
echo '
[Unit]
Description=automatic backup
[Service]
ExecStart=/usr/local/bin/codev backup
Nice=19
KillMode=process
KillSignal=SIGINT' > /usr/local/lib/systemd/system/autobackup.service
echo '
[Unit]
Description=automatic backup timer
[Timer]
OnUnitInactiveSec=1h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target' > /usr/local/lib/systemd/system/autobackup.timer
systemctl enable autobackup.timer

# also when a disk is inserted run "codev backup"

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo '[udisks]
# 1, mount internal devices without asking for password
#   however, Linux system partitions can not be arbitrarily mounted/unmounted,
#     because of "org.freedesktop.udisks2.filesystem-fstab"
# 2, read/write disk images without asking for password (for non-system devices)
Identity=unix-user:*
Action=org.freedesktop.udisks2.filesystem-mount-system;org.freedesktop.udisks2.open-device
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/50-nopasswd.pkla

# despite using BTRFS, in-place writing is needed in two situations:
# , in-place first write for preallocated space, like in torrents
#   we don't want to disable COW for these files
#   apparently supported by BTRFS, isn't it?
#   https://lore.kernel.org/linux-btrfs/20210213001649.GI32440@hungrycats.org/
#   https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
#   https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3
# , virtual machines and databases (eg the one used in Webkit)
#   COW must be disabled for these files
#   generally it's done automatically by the program itself (eg systemd-journald)
#   otherwise we mut do it manually: chattr +C ...
#   apparently Webkit uses SQLite in WAL mode

# to customize dconf default values:
mkdir -p /etc/dconf/profile
echo 'user-db:user
system-db:local
' > /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d
echo "
[org/gnome/desktop/interface]
gtk-theme='Materia-light-compact'
cursor-blink-timeout=1000
document-font-name='sans 10.5'
font-name='sans 10.5'
monospace-font-name='monospace 10.5'
" > /etc/dconf/db/local.d/00-mykeyfile
dconf update

mkdir -p /etc/fonts
echo '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <rejectfont>
      <pattern><patelt name="family"><string>NotoNastaliqUrdu</string></patelt></pattern>
      <pattern><patelt name="family"><string>NotoKufiArabic</string></patelt></pattern>
      <pattern><patelt name="family"><string>NotoNaskhArabic</string></patelt></pattern>
    </rejectfont>
  </selectfont>
  <alias>
    <family>serif</family>
    <prefer><family>NotoSerif</family></prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>sans</family>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>Hack</family></prefer>
  </alias>
</fontconfig>' > /etc/fonts/local.conf

# bash aliases: poweroff, reboot, logout, suspend, lock

cp -r ../comshell-py /usr/local/share/

echo 'installation completed successfully; enter "reboot" to boot into the new system'
