set -e

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

# U-boot "/boot/extlinux/extlinux.conf"
# Petitboot "/boot/syslinux/syslinux.cfg"
# for BIOS'based "x86*" systems install non'UEFI syslinux

# timezone

# sid
# contrib and non-free

# udev kbd acl dosfstools btrfs-progs btrfsmaintenance
# udisks2 libarchive-tools wget
# iwd wireless-regdb modemmanager usb-modeswitch pppoe rfkill iputils-ping wget openssh-client
# wireplumber pipewire-pulse pipewire-audio-client-libraries libspa-0.2-bluetooth bluez
#   ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/99-pipewire-default.conf && true
#   https://salsa.debian.org/utopia-team/pipewire/-/blob/debian/master/debian/pipewire-audio-client-libraries.links
#   https://salsa.debian.org/utopia-team/pipewire/-/blob/debian/master/debian/pipewire-audio-client-libraries.install
# policykit-1 lua5.3 lua-lgi
# fonts-clear-sans fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji
# emacs-gtk elpa-treemacs

# materia-gtk-theme gst-plugins-{base,good,bad} gst-libav sway alacritty xorg-server-xwayland
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

cp net /usr/local/bin/net

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

# run this before creating user in "preseed.cfg"
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

# run this before creating user in "preseed.cfg"
mkdir -p /etc/skel/.config/sway
cp sway /etc/skel/.config/sway/config

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

cp ./format /usr/local/bin/
chmod +x /usr/local/bin/sd

cp apm /usr/local/bin/
chmod +x /usr/local/bin/apm

cp fwi /usr/local/bin/
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

cp ./codev /usr/local/bin/
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
