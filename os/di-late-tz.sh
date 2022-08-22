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
' > /usr/local/share/tz-check.service

echo -n '[Unit]
Description=timezone check timer
[Timer]
OnBootSec=1
OnUnitInactiveSec=5min
RandomizedDelaySec=1min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/tz-check.timer

systemctl enable /usr/local/share/tz-check.timer

echo -n '#!/usr/bin/pkexec /bin/sh
. /usr/share/debconf/confmodule
db_set time/zone "$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
db_fset time/zone seen false
DEBIAN_FRONTEND=text dpkg-reconfigure tzdata
rm /usr/local/share/tz-geoip
' > /usr/local/bin/tz
