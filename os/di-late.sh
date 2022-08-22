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

. /mnt/comshell/os/di-late-bootloader.sh

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
# https://wiki.archlinux.org/title/udev
# https://wiki.debian.org/udev
# https://salsa.debian.org/debian/isenkram/-/blob/master/isenkramd
echo 'SUBSYSTEM=="firmware", ACTION=="add",  RUN+="/usr/local/bin/apm firmwares"' >
  /etc/udev/rules.d/80-firmwares.rules

. /mnt/comshell/os/di-late-sd.sh

. /mnt/comshell/os/di-late-su.sh

. /mnt/comshell/os/di-late-tz.sh

. /mnt/comshell/os/di-late-face.sh

[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

cp /mnt/comshell/os/codev.sh /usr/local/share/
# schedule codev backup
echo -n '[Unit]
Description=automatic backup
[Service]
ExecStart=/bin/sh /usr/local/share/codev.sh backup
Nice=19
KillMode=process
KillSignal=SIGINT
' > /usr/local/share/codev-backup.service
echo -n '[Unit]
Description=automatic backup timer
[Timer]
OnUnitInactiveSec=1h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/share/codev-backup.timer
systemctl --global enable /usr/local/share/codev-backup.timer

cp /mnt/comshell/os/{sway.conf,status.py,swapps.py} /usr/local/share/

cp -r /mnt/comshell/comshell-py /usr/local/share/

echo 'installation completed successfully; enter "reboot" to boot into the new system'
