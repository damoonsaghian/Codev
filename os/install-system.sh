apt-get -qq install iwd wireless-regdb bluez rfkill passwd fzy

this_directory="$(dirname "$0")"
cp "$this_directory/system" /usr/local/bin/
chmod +x /usr/local/bin/system

systemctl enable iwd.service

echo '# allow rfkill for users in the netdev group
KERNEL=="rfkill", MODE="0664", GROUP="netdev"
' > /etc/udev/rules.d/80-rfkill.rules

echo; echo "setting timezone"
# guess the timezone, but let the user to confirm it
command -v wget > /dev/null 2>&1 || apt-get -qq install wget > /dev/null 2>&1 || true
geoip_tz="$(wget -q -O- 'http://ip-api.com/line/?fields=timezone')"
geoip_tz_continent="$(echo "$geoip_tz" | cut -d / -f1)"
geoip_tz_city="$(echo "$geoip_tz" | cut -d / -f2)"
tz_continent="$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5 |
	fzy -p "select a continent: " -q "$geoip_tz_continent")"
tz_city="$(ls -1 /usr/share/zoneinfo/"$tz_continent"/* | cut -d / -f6 |
	fzy -p "select a city: " -q "$geoip_tz_city")"
ln -sf "/usr/share/zoneinfo/${tz_continent}/${tz_city}" /etc/localtime

echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.timedate1.set-timezone" &&
		subject.local && subject.active
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-timezone.rules

# let any user to run "pkexec apt-get update"
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="org.local.pkexec.apt-update">
		<description>let any user to run "pkexec apt-get update"</description>
		<message>let any user to run "pkexec apt-get update"</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/usr/bin/apt-get</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">update</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/org.local.pkexec.apt-update.policy

# https://www.freedesktop.org/wiki/Software/systemd/inhibit/
cat <<'__EOF__' > /usr/local/bin/system-packages
#!/bin/sh
mode="$1" package_name="$2"

autoupdate() {
	metered_connection() {
		local active_net_device="$(ip route show default | head -1 | sed -n "s/.* dev \([^\ ]*\) .*/\1/p")"
		local is_metered=false
		case "$active_net_device" in
			ww*) is_metered=true ;;
		esac
		# todo: DHCP option 43 ANDROID_METERED
		$is_metered
	}
	metered_connection && exit 0
	apt-get update
	export DEBIAN_FRONTEND=noninteractive
	apt-get -qq -o Dpkg::Options::=--force-confnew dist-upgrade
}

case "$mode" in
	autoupdate) autoupdate ;;
	update) apt-get update; apt-get dist-upgrade ;;
	install) apt-get install -- "$package_name" ;;
	remove) apt-get purge -- "$package_name" ;;
esac

apt-get -qq --purge autoremove
apt-get -qq autoclean
__EOF__
chmod +x /usr/local/bin/system-packages

mkdir -p /usr/local/lib/systemd/system
echo -n '[Unit]
Description=automatic update
ConditionACPower=true
After=network-online.target
[Service]
Type=oneshot
ExecStartPre=-/usr/lib/apt/apt-helper wait-online
ExecStart=/usr/local/bin/system-packages autoupdate
KillMode=process
TimeoutStopSec=900
Nice=19
' > /usr/local/lib/systemd/system/automatic-update.service
echo -n '[Unit]
Description=automatic update
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/automatic-update.timer
systemctl enable automatic-update.timer
