set -e

cd "$(dirname "$0")"

comshell_url="https://hashbang.sh/~damoonsaghian/Comshell/"

btrfs subvolume create /0
btrfs subvolume snapshot / /0

rm -r /0/etc/* /0/home/* /0/root/* /0/opt/* /0/usr/local/* /0/srv/* /0/var/*
rm -d /0/0

mount --bind /boot/efi /0/boot/efi

# directories witch must change atomically during an upgrade
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

# timezone

# sid
# contrib and non-free
# no recommends

# udev kbd acl attr dosfstools btrfs-progs btrfsmaintenance
# iwd wireless-regdb modemmanager usb-modeswitch pppoe rfkill
# wireplumber pipewire-pulse pipewire-audio-client-libraries libspa-0.2-bluetooth bluez
#   ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/99-pipewire-default.conf || true
#   https://salsa.debian.org/utopia-team/pipewire/-/blob/debian/master/debian/pipewire-audio-client-libraries.links
#   https://salsa.debian.org/utopia-team/pipewire/-/blob/debian/master/debian/pipewire-audio-client-libraries.install
# policykit-1 lua5.3 lua-lgi
# sway xwayland iputils-ping
# fonts-clear-sans fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji
# gvfs openssh-client gnupg lftp
# why lftp:
# , curl and wget: no status file, no preallocation
# , aria2: no http POST
# emacs-gtk elpa-treemacs

# materia-gtk-theme gst-plugins-{base,good,bad} gst-libav
# gir packages

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

lftp -c "cat $comshell_url/os/net" > /usr/local/bin/net
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

echo '[[ -f ~/.profile ]] && . ~/.profile

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

exec sway
' > /etc/skel/.bash_profile

echo '#!/bin/sh
# the next available virtual terminal
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
chvt $navt
' > /usr/local/bin/navt
chmod u+s,+x /usr/local/bin/navt

# when keyboard/headset is disconnected, lock session, run "navt"

mkdir -p /etc/skel/.config/sway
lftp -c "cat $comshell_url/os/sway" > /etc/skel/.config/sway/config

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

lftp -c "cat $comshell_url/os/sd" > /usr/local/bin/sd
chmod +x /usr/local/bin/sd

lftp -c "cat $comshell_url/os/apm" > /usr/local/bin/apm
chmod +x /usr/local/bin/apm

lftp -c "cat $comshell_url/os/fwi" > /usr/local/bin/fwi
chmod +x /usr/local/bin/fwi
fwi

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

# comup.sh -> update the files in an installed system

lftp -c "cat $comshell_url/os/codev" > /usr/local/bin/codev
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
# , in-place first write for preallocated space (apparently supported by BTRFS, isn't it?)
# , databases (eg the one used in Webkit): chattr +C ...

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
    <prefer><family>ClearSans</family></prefer>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>sans</family>
    <prefer><family>ClearSans</family></prefer>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>Hack</family></prefer>
  </alias>
</fontconfig>' > /etc/fonts/local.conf

echo 'installation completed successfully; enter "reboot" to boot into the new system'
