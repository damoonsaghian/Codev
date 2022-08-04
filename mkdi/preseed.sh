set -e

# install these packages (no recommends):
# dosfstools exfatprogs btrfs-progs udisks2 polkitd
# iwd wireless-regdb modemmanager rfkill
# wireplumber pipewire-pulse pipewire-audio-client-libraries libspa-0.2-bluetooth
#   https://wiki.debian.org/PipeWire#Debian_Testing.2FUnstable
# dbus-user-session
# vlock
# kbd is needed for its chvt
# sway swayidle swaylock wofi grim xwayland
# i3pystatus python3-colour python3-netifaces
# python3-cffi python3-cairocffi
# foot tmux
# fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji materia-gtk-theme
# openssh-client wget2 gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as a dependency
# libarchive-tools
# libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf
# python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18

btrfs subvolume create /1
btrfs subvolume snapshot / /1

rm -rf /1/etc/* /1/home/* /1/root/* /1/opt/* /1/usr/local/* /1/srv/* /1/var/*
rm -df /1/1

ln --symbolic /1 /0

# directories which must change atomically during an upgrade
ln --symbolic --force -t / /0/bin
ln --symbolic --force -t / /0/boot
ln --symbolic --force -t / /0/lib
ln --symbolic --force -t / /0/lib64
ln --symbolic --force -t / /0/sbin
ln --symbolic --force -t / /0/usr

# flash-kernel way of dealing with kernel and initrd images is very diverse
# this makes implementing atomic upgrades impossible
# so see if flash-kernel is installed, remove it and warn the user
#
# MIPS systems are not supported for a similar reason
#   (newer MIPS systems may not have this problem, but MIPS is moving to RISCV anyway, so why bother)
# also s390x is not supported because
#   ZIPL (the bootloader on s390x) only understands data'blocks (not a filesystem),
#   and the boot partition must be rewritten everytime kernel/initrd is updated
#
# bootloader:
# , for UEFI use systemd-boot
# , for Bios and PPC (OpenFirmware, Petitboot) use Grub

# UEFI needs a separate VFAT boot partition
# separate boot partition and atomic upgrades can live together becasue Debian keeps old kernel and modules
# and the fact that systemd-boot implements boot counting and automatic fallback to
#   older working boot entries on failure
#   https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/
# https://manpages.debian.org/unstable/systemd-boot/systemd-boot.7.en.html
[ -d /boot/efi ] && {
  apt-get install --yes systemd-boot

  mkdir /boot/efi/loader
  echo 'timeout 0
  editor no' > /boot/efi/loader/loader.conf

  bootctl install --no-variables --esp-path=/boot/efi

  echo 1 > /etc/kernel/tries

  root_uuid="$(findmnt -n -o UUID /)"
  echo "root=UUID=$root_uuid ro quiet" > /etc/kernel/cmdline

  kernel_path=$(readlink -f /boot/vmlinu?)
  kernel_version="$(basename $kernel_path | sed -e 's/vmlinu.-//')"
  kernel-install add "$kernel_version" "$kernel_path" /boot/initrd.img-"$kernel_version"

  rm -f /etc/kernel/cmdline
}

# alternative method:
# bootctl remove --esp-path=/boot/efi
# change root partition's type to XBOOTLDR
# create /loader/entries/debian.conf which refers to these symlinks: /boot/vmlinu? /boot/initrd.img
# put BTRFS driver in /boot/efi//EFI/systemd/drivers/...arch.efi
# cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI

# to have atomic upgrades for BIOS and OpenFirmware based systems,
#   the bootloader is installed once, and never updated
lock_grub () {
  echo '
  GRUB_TIMEOUT=0
  GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub
  # disable menu editing and other admin operations in Grub:
  echo '#! /bin/sh
  set superusers=""
  set menuentry_id_option="--unrestricted $menuentry_id_option"' > /etc/grub.d/09_user
  chmod +x /etc/grub.d/09_user
  grub-mkconfig -o /boot/grub/grub.cfg
}
[ "$(dpkg --print-architecture)" = 'i386' ] && [ ! -d /sys/firmware/efi ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$(udpkg --print-architecture)" = 'amd64' ] && [ ! -d /sys/firmware/efi ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$(udpkg --print-architecture)" = 'ppc64el' ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-ieee1275-bin grub-ieee1275
  apt-get remove --yes grub-ieee1275
  lock_grub
}

# boot'firmware updates need special care
# unless there is a read_only backup, firmware update is not a good idea
# fwupd

# automatic time'zone:
# periodically check for location and if it's not the same as the set timezone,
#   and it's not equal to the value in "/usr/local/share/tz-extra",
#   overwrite the time'zone in "/usr/local/share/tz-extra"
# timezone="$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
#
# if the file exists and it's older than a week then change the timezone, and delete the file
# timedatectl set-timezone "$timezone"
#
# networkd-dispatcher package
# https://gitlab.com/craftyguy/networkd-dispatcher
# https://manpages.debian.org/unstable/networkd-dispatcher/networkd-dispatcher.8.en.html
# systemd-networkd-wait-online

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
RouteMetric=100' > /etc/systemd/network/20-wired.network
echo '[Match]
Type=wlan
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600' > /etc/systemd/network/20-wireless.network
echo '[Match]
Type=wwan
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=700
[IPv6AcceptRA]
RouteMetric=700' > /etc/systemd/network/20-wwan.network
systemctl enable systemd-networkd
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved
systemctl enable iwd

cp /mnt/comshell/os/net /usr/local/bin/
chmod +x /usr/local/bin/net

cp /mnt/comshell/os/bt /usr/local/bin/
chmod +x /usr/local/bin/bt

echo '#!/bin/sh
rfkill $1 $2' > /usr/local/bin/rd
# is this necessary?
chgrp netdev /usr/local/bin/rd
chmod u+s,ug+x /usr/local/bin/rd

echo '#!/bin/sh
if [ $1 = disable ]; then
  rm -f /etc/systemd/system/getty@tty1.service.d/override.conf
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
autologin enable <user>"' > /usr/local/bin/autologin
chmod +x /usr/local/bin/autologin

echo '#!/bin/sh
# save current vt as the last vt
echo "$(fgconsole)" > /tmp/su-lvt
# the next available virtual terminal
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
loginctl lock-session
chvt "$navt"
echo "$navt" > /tmp/su-vt' > /usr/local/bin/su
chmod u+s,+x /usr/local/bin/su

echo '# run this script if running from tty1, or if put here by "su"
if [ "$(tty)" = "/dev/tty1" ] || [ "$(fgconsole)" = "$(cat /tmp/su-vt)" ]; then
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
  [ "$USER" = root ] || exec sway -c /usr/local/share/sway.conf
fi' > /etc/profile.d/login-manager.sh

# when a keyboard is connected, disable others, lock the session (if any), run "su"
# since password prompts only accept keyboard input, this is not necessary for headsets
# this has two benefits:
# , when you want to login you are sure that it's the login screen (not a fake one created by another user)
# , others can't access your session using another keyboard

cp /mnt/comshell/os/{sway.conf,status.py,swapps.py} /usr/local/share/

echo 'font=monospace:size=10.5
dpi-aware=no
initial-window-size-chars=120x55
pad=0x0 center
[scrollback]
indicator-position=none
[cursor]
blink=yes
[colors]
# alpha=1.0
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
bright7=fefbec' > /usr/local/share/foot.ini

# https://github.com/tmux/tmux/wiki
# https://wiki.archlinux.org/title/Tmux
# https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/
# use copy-mode to find the privious character
#   copy-pipe-and-cancel [<command>] [<prefix>]
# and then:
# , double space -> completion
# , comma + character -> punctuations
# , two apostrophes + a letter -> capital letter
# http://man.openbsd.org/OpenBSD-current/man1/tmux.1#send-keys
# https://github.com/tmux/tmux/wiki/Advanced-Use#basics-of-scripting
# https://unix.stackexchange.com/questions/657555/tmux-lock-session-only-when-using-tmux-on-console-not-from-a-graphical-de
# ; # Enable locking (pressing "prefix+l" locks session)
# ; set -g lock-command vlock
# ; set -g lock-after-time 0 # Seconds; 0 = never
# ; bind l lock-session
# hide foot window, or if user is root, run vlock, and switch to last vt

cp /mnt/comshell/os/sd /usr/local/bin/
chmod +x /usr/local/bin/sd
echo '#!/bin/sh -e
format () {
  # if it is not already formated with BTRFS
  mkfs.btrfs /dev/"$1"
}
mount () {
  mkdir -p /run/mount/"$1"
  mount /dev/$1 /run/mount/"$1"
  cp --no-clobber --preserve=all /home/ /run/mount/"$1"
}
case "$1" in
  format) shift; format "$@" ;;
  mount) shift; mount "$@" ;;
  *) echo "usage: sd-internal format/mount"
    exit 1 ;;
esac' > /usr/local/bin/mount-internal
chmod u+s,+x /usr/local/bin/sd-internal

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo '[udisks]
# write disk images, on non-system devices, without asking for password
Identity=unix-user:*
Action=org.freedesktop.udisks2.open-device
ResultActive=yes' > /etc/polkit-1/localauthority/50-local.d/50-nopasswd.pkla

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
#   otherwise we must do it manually: chattr +C ...
#   apparently Webkit uses SQLite in WAL mode

cp /mnt/comshell/os/fwi /usr/local/bin/
chmod +x /usr/local/bin/fwi
# https://wiki.archlinux.org/title/udev
# https://wiki.debian.org/udev
# https://salsa.debian.org/debian/isenkram/-/blob/master/isenkramd
echo 'SUBSYSTEM=="firmware", ACTION=="add",  RUN+="/usr/local/bin/fwi"' >
  /etc/udev/rules.d/80-fwi.rules

cp /mnt/comshell/os/apm /usr/local/bin/
chmod +x /usr/local/bin/apm

mkdir -p /usr/local/lib/systemd/system
echo '[Unit]
Description=automatic update
After=network-online.target
[Service]
ExecStart=/usr/local/bin/apm autoupdate
Nice=19
KillMode=process
KillSignal=SIGINT' > /usr/local/lib/systemd/system/autoupdate.service
echo '[Unit]
Description=automatic update timer
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target' > /usr/local/lib/systemd/system/autoupdate.timer
systemctl enable autoupdate.timer

cp /mnt/comshell/os/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

mkdir -p /usr/local/lib/systemd/system
echo '[Unit]
Description=automatic backup
[Service]
ExecStart=/usr/local/bin/codev backup
Nice=19
KillMode=process
KillSignal=SIGINT' > /usr/local/lib/systemd/system/autobackup.service
echo '[Unit]
Description=automatic backup timer
[Timer]
OnUnitInactiveSec=1h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target' > /usr/local/lib/systemd/system/autobackup.timer
systemctl enable autobackup.timer

# also when a disk is inserted run "codev backup"

# to customize dconf default values:
mkdir -p /etc/dconf/profile
echo 'user-db:user
system-db:local' > /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d
echo "[org/gnome/desktop/interface]
gtk-theme='Materia-light-compact'
cursor-blink-timeout=1000
document-font-name='sans 10.5'
font-name='sans 10.5'
monospace-font-name='monospace 10.5'" > /etc/dconf/db/local.d/00-mykeyfile
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

cp -r /mnt/comshell/comshell-py /usr/local/share/

echo 'installation completed successfully; enter "reboot" to boot into the new system'
