apt-get install --no-install-recommends --yes systemd-resolved iwd wireless-regdb modemmanager bluez rfkill

cp /mnt/comshell/di/system /usr/local/bin/
chmod +x /usr/local/bin/system

cp /mnt/comshell/di/system-network.sh /usr/local/share/
echo -n '[Match]
Name=en*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
' > /etc/systemd/network/20-ethernet.network
echo -n '[Match]
Name=ib*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=200
[IPv6AcceptRA]
RouteMetric=200
' > /etc/systemd/network/20-infiniband.network
echo -n '[Match]
Name=wl*
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
Name=ww*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=700
[IPv6AcceptRA]
RouteMetric=700
' > /etc/systemd/network/20-wwan.network

cp /mnt/comshell/di/system-bluetooth.sh /usr/local/share/

cp /mnt/comshell/di/system-packages /usr/local/bin/
chmod +x /usr/local/bin/system-packages

mkdir -p /usr/local/lib/systemd/system
echo -n '[Unit]
Description=automatic update
After=network-online.target
[Service]
ExecStart=/usr/local/bin/system-packages autoupdate
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

# install the corresponding firmwares when new hardware is inserted into the machine
echo 'SUBSYSTEM=="firmware", ACTION=="add", RUN+="/usr/local/bin/system-packages install-firmware %k"' >
  /etc/udev/rules.d/80-install-firmware.rules

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.system.radio">
    <description>radio device management</description>
    <message>radio device management</message>
    <defaults><allow_active>no</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/sbin/rfkill</annotate>
  </action>
  <action id="comshell.system.packages">
    <description>package management</description>
    <message>package management</message>
    <defaults><allow_active>no</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/system-packages</annotate>
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
