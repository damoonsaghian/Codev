cp "$(dirname "$0")/system" /usr/local/bin/
chmod +x /usr/local/bin/system

apt-get --yes install wpa_supplicant bluez rfkill
cp "$(dirname "$0")/system-connections.sh" /usr/local/share/
echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.policykit.exec" &&
		action.lookup("program") == "/usr/sbin/rfkill" &&
		subject.local && subject.active // && subject.isInGroup("netdev")
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-rfkill.rules

echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.timedate1.set-timezone" &&
		subject.local && subject.active
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-timezone.rules

echo -n '#/bin/sh
mode="$1" package_name="$2"
case "$mode" in
	autoupdate) apt-get --yes update; apt-get --yes dist-upgrade ;;
	update) apt-get update; apt-get dist-upgrade ;;
	install) apt-get install -- "$package_name" ;;
	remove) apt-get purge -- "$package_name" ;;
esac
apt-get --purge --yes autoremove
apt-get --yes autoclean
' > /usr/local/bin/system-packages

# let any user to run "pkexec apt-get update"
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="codev.pkexec.apt.update">
		<description>let any user to run "pkexec apt-get update"</description>
		<message>let any user to run "pkexec apt-get update"</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/usr/bin/apt-get</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">update</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/codev.pkexec.apt.policy

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
