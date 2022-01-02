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

chroot /0 /usr/bin/sh << EOF
# if this is a UEFI system, uninstall GRUB (if it's installed),
#   create a "startup.nsh" file: https://wiki.archlinux.org/title/EFISTUB#Using_a_startup.nsh_script
#   and download the EFI driver for BTRFS: https://efi.akeo.ie/
# otherwise regenerate GRUB, set GRUB password
EOF

# Grub password
# https://superuser.com/questions/488275/grub-2-password-protection-in-debian

# timezone

# sid
# contrib and non-free

apt-get install intel-ucode amd-ucode \
  iwd pipewire-alsa \
  openssh curl materia-gtk-theme unzip gst-plugins-{base,good,bad} gst-libav \
  sway alacritty xorg-server-xwayland

# firmware-linux
# udisks2 dosfstools e2fsprogs btrfs-progs btrfs-progs btrfsmaintenance
# pipewire-pulse policykit-1 lua5.3 lua-lgi
# fonts-clear-sans fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji
# unzip
# emacs-gtk elpa-treemacs

systemctl enable systemd-networkd

echo '#!/bin/sh
if [ "$1" = "disconnect" ]; then
  iwctl station wlan0 disconnect
  exit
fi
iwctl station wlan0 scan
iwctl station wlan0 get-networks
echo -n "select a network: "; read ssid
iwctl station wlan0 connect "$ssid"
' > /usr/local/bin/wlan
chmod +x /usr/local/bin/wlan

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

echo '# if a user session is already running, switch to it, unlock it, and exit
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
' > /etc/profile.d/session-manager.sh

echo '#!/bin/sh
# the next available virtual terminal
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
chvt $navt
' > /usr/local/bin/navt
chmod +x /usr/local/bin/navt

# when keyboard/headset is disconnected, lock session, run "navt"

echo '
# open a Wayland window demanding the sudo password (not the user password)
# https://unix.stackexchange.com/questions/329878/check-users-password-with-a-shell-script
# https://unix.stackexchange.com/questions/21705/how-to-check-password-with-linux
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
' > /usr/local/bin/sudo
chgrp sudo /usr/local/bin/sudo
chmod u+s,ug+x /usr/local/bin/sudo

# create a user named "sudo" with a password equal to the root password
# lock its shell
usermod -s /usr/sbin/nologin sudo
# lock root
passwd -l root

cp ./format /usr/local/bin/
chmod +x /usr/local/bin/format

cp ./apm /usr/local/bin/
chmod +x /usr/local/bin/apm

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
