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
if [ -n $1 = disable ]; then
  rm /etc/systemd/system/getty@tty1.service.d/override.conf
  exit
fi
if [ -n $1 = enable ]; then
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  printf "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I $TERM" >
    /etc/systemd/system/getty@tty1.service.d/override.conf
  exit
fi
echo "usage: autologin enable/disable"
' > /usr/local/bin/autologin
chmod +x /usr/local/bin/autologin

cp ./apm /usr/local/bin/
chmod +x /usr/local/bin/apm

echo '
# open a Wayland window demanding the root password (not the user password)
# https://stackoverflow.com/questions/18035093/given-a-linux-username-and-a-password-how-can-i-test-if-it-is-a-valid-account
' > /usr/local/bin/sudo
chmod u+s,+x /usr/local/bin/sudo

# lock root login
usermod -s /usr/sbin/nologin root

cp ./format /usr/local/bin/
chmod +x /usr/local/bin/format

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

# display manager
# https://github.com/loh-tar/tbsm/tree/master/src
#   https://github.com/loh-tar/tbsm/blob/master/doc/01_Manual.txt
# https://github.com/evertiro/cdm/tree/master/src
# https://github.com/nullgemm/ly
# https://github.com/tvrzna/emptty/
# https://wiki.archlinux.org/title/SDDM
#   https://packages.debian.org/sid/sddm

# lock screen when keyboard/headset is disconnected
