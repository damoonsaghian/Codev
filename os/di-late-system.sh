echo -n '#!/bin/sh -e

# /usr/bin/pkexec /bin/sh radio.sh

echo -n "
, session
, timezone
, network
, bluetooth
, radio
, packages
select one by typing the first charactor at the least (session is default): "
read -r selected_option

case "$selected_option" in
  t*) pkexec sh /usr/local/share/timezone.sh ;;
  n*) sh /usr/local/share/network.sh ;;
  b*) sh /usr/local/share/bluetooth.sh ;;
  r*) pkexec sh /usr/local/share/radio.sh ;;
  p*) pkexec sh /usr/local/share/packages.sh ;;
  *) sh /usr/local/share/session.sh ;;
esac
' > /usr/local/bin/system
chmod +x /usr/local/bin/system

echo -n 'set -e
echo -n "
, lock
, suspend
, exit
, reboot
, poweroff
select one by typing the first charactor at the least (lock is default): "
read -r selected_option

case "$selected_option" in
  s*) systemctl suspend ;;
  e*) loginctl terminate-session ;;
  r*) systemctl reboot ;;
  p*) systemctl poweroff ;;
  *) loginctl lock-session ;;
esac
' > /usr/local/share/session.sh

echo -n '#!/usr/bin/pkexec /bin/sh
. /usr/share/debconf/confmodule
db_set time/zone "$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
db_fset time/zone seen false
DEBIAN_FRONTEND=text dpkg-reconfigure tzdata
' > /usr/local/share/timezone.sh

# https://lazka.github.io/pgi-docs/ModemManager-1.0/classes/NetworkTimezone.html

cp /mnt/comshell/os/network.sh /usr/local/share/

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

cp /mnt/comshell/os/bluetooth.sh /usr/local/share/

echo -n 'set -e
rfkill
echo "select radio devices to toggle their block/unblock states"
printf "or enter \"block\" to block all (default: unblock all): "
read -r devices
[ -z "$devices" ] && { rfkill unblock all; exit; }
[ "$devices" = "block" ] && { rfkill block all; exit; }
rfkill toggle "$devices"
' > /usr/local/share/radio.sh

cp /mnt/comshell/os/packages.sh /usr/local/share/

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

# install needed firmwares when new hardware is inserted into the machine
echo 'SUBSYSTEM=="firmware", ACTION=="add",  RUN+="/usr/local/bin/apm install-firmware %k"' >
  /etc/udev/rules.d/80-install-firmware.rules
