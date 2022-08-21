set -e

apt-get update
apt-get install --no-install-recommends --yes systemd-resolved iwd wireless-regdb modemmanager bluez rfkill \
  wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth \
  dbus-user-session kbd pkexec \
  sway swayidle swaylock xwayland \
  fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji materia-gtk-theme \
  python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 python3-cairocffi \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  dosfstools exfatprogs btrfs-progs udisks2 polkitd \
  libarchive-tools \
  openssh-client wget2 gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency (through libgpgme11)
# kbd is needed for its chvt and openvt

# flash-kernel way of dealing with kernel and initrd images is very diverse
# this makes implementing atomic upgrades impossible
# so see if flash-kernel is installed, remove it and warn the user
command -v flash-kernel &>/dev/null && {
  apt-get remove --yes flash-kernel
  echo 'apparently your system needs "flash-kernel" package to boot'
  echo '  but since "flash-kernel" is not supported, your system may not boot'
}
# MIPS systems are not supported for a similar reason
#   (newer MIPS systems may not have this problem, but MIPS is moving to RISCV anyway, so why bother)
# also s390x is not supported because
#   ZIPL (the bootloader on s390x) only understands data'blocks (not a filesystem),
#   and the boot partition must be rewritten everytime kernel/initrd is updated
# so for the bootloader we only have to deal with these:
# , for UEFI use systemd-boot
# , for Bios and PPC (OpenFirmware, Petitboot) use Grub

# UEFI with systemd-boot needs a separate VFAT partition containing kernel and initrd images
# this and atomic upgrades can live together becasue Debian keeps old kernel and modules
# and the fact that systemd-boot implements boot counting and automatic fallback to
#   older working boot entries on failure
# https://manpages.debian.org/unstable/systemd-boot/systemd-boot.7.en.html#BOOT_COUNTING
# https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/
[ -d /boot/efi ] && {
  apt-get install --yes systemd-boot
  mkdir /boot/efi/loader
  printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
  bootctl install --no-variables --esp-path=/boot/efi
  echo 1 > /etc/kernel/tries
  echo "root=UUID=$(findmnt -n -o UUID /) ro quiet" > /etc/kernel/cmdline
  kernel_path=$(readlink -f /boot/vmlinu?)
  kernel_version="$(basename $kernel_path | sed -e 's/vmlinu.-//')"
  kernel-install add "$kernel_version" "$kernel_path" /boot/initrd.img-"$kernel_version"
  rm -f /etc/kernel/cmdline
}

# to have atomic upgrades for BIOS and OpenFirmware based systems,
#   the bootloader is installed once, and never updated
lock_grub () {
  # since we will lock root, recovery entries are useless
  printf '\nGRUB_DISABLE_RECOVERY=true\nGRUB_DISABLE_OS_PROBER=true\nGRUB_TIMEOUT=0\n' >> /etc/default/grub
  # disable menu editing and other admin operations in Grub:
  echo '#! /bin/sh' > /etc/grub.d/09_user
  echo 'set superusers=""' >> /etc/grub.d/09_user
  echo 'set menuentry_id_option="--unrestricted $menuentry_id_option"' >> /etc/grub.d/09_user
  chmod +x /etc/grub.d/09_user
  grub-mkconfig -o /boot/grub/grub.cfg
}
architecture="$(udpkg --print-architecture)"
[ -d /sys/firmware/efi ] || { [ "$architecture" = 'i386' ] || [ "$architecture" = 'amd64' ]; } && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$architecture" = 'ppc64el' ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-ieee1275-bin grub-ieee1275
  apt-get remove --yes grub-ieee1275
  lock_grub
}

echo -n '[Match]
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
echo -n '[Match]
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
echo -n '[Match]
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

cp /mnt/comshell/os/net /usr/local/bin/
chmod +x /usr/local/bin/net

cp /mnt/comshell/os/bt /usr/local/bin/
chmod +x /usr/local/bin/bt

echo -n '#!/usr/bin/pkexec /bin/sh
# do not know if pkexec is necessary, or rfkill can be run by a netdev user
set -e
rfkill
printf "select the type of radio device to toggle its block/unblock state (leave empty to select all): "
read -r device_type
[ -z "$device_type" ] && device_type=all
rfkill toggle "$device_type"
' > /usr/local/bin/rd
chmod +x /usr/local/bin/rd

cp /mnt/comshell/os/sd /usr/local/bin/
chmod +x /usr/local/bin/sd
echo -n '#!/usr/bin/pkexec /bin/sh
set -e
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
esac
' > /usr/local/bin/sd-internal
chmod +x /usr/local/bin/sd-internal

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[udisks]
# write disk images, on non-system devices, without asking for password
Identity=unix-user:*
Action=org.freedesktop.udisks2.open-device
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
#   otherwise we must do it manually: chattr +C ...
#   apparently Webkit uses SQLite in WAL mode

cp /mnt/comshell/os/fwi /usr/local/bin/
chmod +x /usr/local/bin/fwi
# https://wiki.archlinux.org/title/udev
# https://wiki.debian.org/udev
# https://salsa.debian.org/debian/isenkram/-/blob/master/isenkramd
echo 'SUBSYSTEM=="firmware", ACTION=="add",  RUN+="/usr/local/bin/fwi"' > /etc/udev/rules.d/80-fwi.rules

cp /mnt/comshell/os/apm /usr/local/bin/
chmod +x /usr/local/bin/apm

echo -n '[Unit]
Description=automatic update
After=network-online.target
[Service]
ExecStart=/usr/local/bin/apm autoupdate
Nice=19
KillMode=process
KillSignal=SIGINT
' > /usr/local/lib/systemd/system/autoupdate.service
echo -n '[Unit]
Description=automatic update timer
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/autoupdate.timer
systemctl enable /usr/local/lib/systemd/system/autoupdate.timer

echo -n 'tz_system="$(timedatectl show --value --property Timezone)"
tz_geoip="$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
if [ "$tz_geoip" = "$tz_system" ]; then
  rm /usr/local/share/tz-geoip
else
  tz_geoip_old="$(cat /usr/local/share/tz-geoip)"
  [ "$tz_geoip" = "$tz_geoip_old" ] || echo "$tz_geoip" > /usr/local/share/tz-geoip
fi
' > /usr/local/share/tz-check.sh
echo -n '[Unit]
Description=timezone check
After=network-online.target
[Service]
ExecStart=/bin/sh /usr/local/share/tz-check.sh
Nice=19
KillMode=process
KillSignal=SIGINT
' > /usr/local/lib/systemd/system/tz-check.service
echo -n '[Unit]
Description=timezone check timer
[Timer]
OnBootSec=1
OnUnitInactiveSec=5min
RandomizedDelaySec=1min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/tz-check.timer
systemctl enable /usr/local/lib/systemd/system/tz-check.timer

echo -n '#!/usr/bin/pkexec /bin/sh
. /usr/share/debconf/confmodule
db_set time/zone "$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
db_fset time/zone seen false
DEBIAN_FRONTEND=text dpkg-reconfigure tzdata
rm /usr/local/share/tz-geoip
' > /usr/local/bin/tz

groupadd su
# add the first user to su group
usermod -aG su "$(id -nu 1000)"

echo -n '
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
loginctl lock-session
chvt "$navt"
echo "$navt" > /tmp/su-vt
' > /usr/local/bin/switch-user
chmod +x /usr/local/bin/switch-user

echo -n '#!/usr/bin/pkexec /bin/sh
set -e
# switch to the first available virtual terminal and ask for root password
# openvt -sw ...
# if the password is equal to correct run $@
# getent shadow root | cut -d: -f2 | cut -c2-
# https://unix.stackexchange.com/questions/329878/check-users-password-with-a-shell-script
# https://unix.stackexchange.com/questions/21705/how-to-check-password-with-linux
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
' > /usr/local/bin/su
chmod +x /usr/local/bin/su
# lock root account
passwd --lock root

echo -n '# run this script if running from tty1, or if put here by "su"
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
fi
' > /etc/profile.d/login-manager.sh

# when a keyboard is connected, disable others, lock the session (if any), run "su"
# since password prompts only accept keyboard input, this is not necessary for headsets
# this has two benefits:
# , when you want to login you are sure that it's the login screen (not a fake one created by another user)
# , others can't access your session using an extra keyboard

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="com.comshell.su">
    <description>switch users</description>
    <message>switch users</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/su</annotate>
  </action>
  <action id="com.comshell.rd">
    <description>radio device management</description>
    <message>radio device management</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/rd</annotate>
  </action>
  <action id="com.comshell.apm">
    <description>package management</description>
    <message>package management</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/apm</annotate>
  </action>
  <action id="com.comshell.tz">
    <description>set timezone</description>
    <message>set timezone</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/tz</annotate>
  </action>
  <action id="com.comshell.switch-user">
    <description>switch user</description>
    <message>switch user</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/switch-user</annotate>
  </action>
  <action id="com.comshell.sd-internal">
    <description>internal storage device management</description>
    <message>internal storage device management</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sd-internal</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/com.comshell.policy

echo -n '[su]
Identity=unix-group:su
Action=com.comshell.su
ResultActive=yes
[rd]
Identity=unix-group:netdev
Action=com.comshell.rd
ResultActive=yes
[apm]
Identity=unix-group:su
Action=com.comshell.apm
ResultActive=yes
[tz]
Identity=unix-group:su
Action=com.comshell.tz
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/51-comshell.pkla

[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

cp /mnt/comshell/os/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

mkdir -p /usr/local/lib/systemd/system
echo -n '[Unit]
Description=automatic backup
[Service]
ExecStart=/usr/local/bin/codev backup
Nice=19
KillMode=process
KillSignal=SIGINT
' > /usr/local/lib/systemd/system/autobackup.service
echo -n '[Unit]
Description=automatic backup timer
[Timer]
OnUnitInactiveSec=1h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/autobackup.timer
systemctl enable /usr/local/lib/systemd/system/autobackup.timer

# also when a disk is inserted run "codev backup"

mkdir -p /usr/local/share
cp /mnt/comshell/os/{sway.conf,status.py,swapps.py} /usr/local/share/

# to customize dconf default values:
mkdir -p /etc/dconf/profile
printf 'user-db:user\nsystem-db:local\n' > /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d
echo -n "[org/gnome/desktop/interface]
gtk-theme='Materia-light-compact'
cursor-blink-timeout=1000
document-font-name='sans 10.5'
font-name='sans 10.5'
monospace-font-name='monospace 10.5'
" > /etc/dconf/db/local.d/00-mykeyfile
dconf update

mkdir -p /etc/fonts
echo -n '<?xml version="1.0"?>
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
</fontconfig>
' > /etc/fonts/local.conf

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

cp -r /mnt/comshell/comshell-py /usr/local/share/

echo 'installation completed successfully; enter "reboot" to boot into the new system'
