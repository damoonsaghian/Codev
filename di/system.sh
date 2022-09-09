apt-get install --no-install-recommends --yes fzy systemd-resolved iwd wireless-regdb modemmanager bluez rfkill

echo -n '#!/bin/sh
selected_option="$(printf "session\ntimezone\nnetwork\nbluetooth\nradio\npackages" | fzy)"
case "$selected_option" in
  session) sh /usr/local/share/system-session.sh ;;
  timezone) pkexec sh /usr/local/share/system-timezone.sh ;;
  network) sh /usr/local/share/system-network.sh ;;
  bluetooth) sh /usr/local/share/system-bluetooth.sh ;;
  radio) pkexec sh /usr/local/share/system-radio.sh ;;
  packages) pkexec sh /usr/local/share/system-packages.sh ;;
esac
' > /usr/local/bin/system
chmod +x /usr/local/bin/system

echo -n 'selected_option="$(printf "lock\nexit\nsuspend\nreboot\npoweroff" | fzy)"
case "$selected_option" in
  lock) loginctl lock-session ;;
  exit) swaymsg "[title=*] kill; exit" ;;
  suspend) systemctl suspend ;;
  reboot) systemctl reboot ;;
  poweroff) systemctl poweroff ;;
esac
' > /usr/local/share/system-session.sh

echo -n 'set -e
auto_timezone="$(wget2 -q -O- http://ip-api.com/line/?fields=timezone)"
auto_continent="$(echo "$timezone" | cut -d / -f1)"
auto_city="$(echo "$timezone" | cut -d / -f2)"
continents="${auto_continent}\n$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5 | fzy)"
city="${auto_city}\n$(ls -1 /usr/share/zoneinfo/"$continent"/* | cut -d / -f6 | fzy)"
timedatectl set-timezone "${continent}/${city}"
' > /usr/local/share/system-timezone.sh

# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/gdbus-org.freedesktop.ModemManager1.Modem.Time.html
# https://manpages.debian.org/bullseye/modemmanager/mmcli.1.en.html
# https://lazka.github.io/pgi-docs/ModemManager-1.0/classes/NetworkTimezone.html
# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/

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

echo -n 'lines="all\n$(rfkill -n -o "TYPE,SOFT,HARD")"
device="$(printf "$lines" | fzy | cut -d " " -f1)"
action="$(printf "block\nunblock" | fzy)"
rfkill "$action "$device"
' > /usr/local/share/system-radio.sh

cp /mnt/comshell/di/system-packages.sh /usr/local/share/

mkdir -p /usr/local/lib/systemd/system
echo -n '[Unit]
Description=automatic update
After=network-online.target
[Service]
ExecStart=/bin/sh /usr/local/bin/system-packages autoupdate
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
echo 'SUBSYSTEM=="firmware", ACTION=="add",  RUN+="/usr/local/bin/system-packages install-firmware %k"' >
  /etc/udev/rules.d/80-install-firmware.rules

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.system.radio">
    <description>radio device management</description>
    <message>radio device management</message>
    <defaults><allow_active>no</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/system-radio.sh</annotate>
  </action>
  <action id="comshell.system.packages">
    <description>package management</description>
    <message>package management</message>
    <defaults><allow_active>no</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/system-packages.sh</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.system.policy

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[timezone]
Identity=unix-group:su
Action=org.freedesktop.timedate1.set-timezone
ResultActive=yes
[radio]
Identity=unix-group:netdev
Action=comshell.system.radio
ResultActive=yes
[packages]
Identity=unix-group:su
Action=comshell.system.packages
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/comshell.system.pkla
