set -e

apt-get update
apt-get install --no-install-recommends iwd wireless-regdb modemmanager bluez rfkill \
  wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth \
  dbus-user-session kbd pkexec \
  sway swayidle swaylock xwayland \
  fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji materia-gtk-theme \
  python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 python3-cairocffi \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  dosfstools exfatprogs btrfs-progs udisks2 polkitd \
  libarchive-tools \
  openssh-client wget2 gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency
# kbd is needed for its chvt and openvt

. /mnt/comshell/s-bootloader.sh

# when critical battery charge is reached, even when asleep, run poweroff

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
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved
systemctl enable iwd

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

mkdir -p /usr/local/lib/systemd/system
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
systemctl enable autoupdate.timer

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
systemctl enable autobackup.timer

# also when a disk is inserted run "codev backup"

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
