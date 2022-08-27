echo -n '#!/bin/sh -e
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
  p*) pkexec sh /usr/local/share/packages.sh ;;
  r*) pkexec sh /usr/local/share/radio.sh ;;
  b*) sh /usr/local/share/bluetooth.sh ;;
  n*) sh /usr/local/share/network.sh ;;
  t*) pkexec sh /usr/local/share/timezone.sh ;;
  *) sh /usr/local/share/session.sh ;;
esac
' > /usr/local/bin/system
chmod +x /usr/local/bin/system

echo -n 'set -e
echo -n "
, lock
, exit
, suspend
, reboot
, poweroff
select one by typing the first charactor at the least (lock is default): "
read -r selected_option
case "$selected_option" in
  p*) systemctl poweroff ;;
  r*) systemctl reboot ;;
  s*) systemctl suspend ;;
  e*) swaymsg "[title=*] kill; exit" ;;
  *) loginctl lock-session ;;
esac
' > /usr/local/share/session.sh

echo -n 'set -e
. /usr/share/debconf/confmodule
db_set time/zone "$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
db_fset time/zone seen false
DEBIAN_FRONTEND=text dpkg-reconfigure tzdata
' > /usr/local/share/timezone.sh

# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/gdbus-org.freedesktop.ModemManager1.Modem.Time.html
# https://manpages.debian.org/bullseye/modemmanager/mmcli.1.en.html
# https://lazka.github.io/pgi-docs/ModemManager-1.0/classes/NetworkTimezone.html
# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/

apt-get install --no-install-recommends --yes systemd-resolved iwd wireless-regdb modemmanager bluez rfkill

cp /mnt/comshell/di/system-network.sh /usr/local/share/
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

cp /mnt/comshell/di/system-bluetooth.sh /usr/local/share/

echo -n 'set -e
rfkill
echo "select radio devices to toggle their block/unblock states"
printf "or enter \"block\" to block all (default: unblock all): "
read -r devices
[ -z "$devices" ] && { rfkill unblock all; exit; }
[ "$devices" = "block" ] && { rfkill block all; exit; }
rfkill toggle "$devices"
' > /usr/local/share/radio.sh

cp /mnt/comshell/di/system-packages.sh /usr/local/share/

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

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.system.tz">
    <description>set timezone</description>
    <message>set timezone</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/tz</annotate>
  </action>
  <action id="comshell.system.rd">
    <description>radio device management</description>
    <message>radio device management</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/rd</annotate>
  </action>
  <action id="comshell.system.apm">
    <description>package management</description>
    <message>package management</message>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/apm</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.system.policy

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[tz]
Identity=unix-group:su
Action=comshell.system.tz
ResultActive=yes
[rd]
Identity=unix-group:netdev
Action=comshell.system.rd
ResultActive=yes
[apm]
Identity=unix-group:su
Action=comshell.system.apm
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/comshell.system.pkla
