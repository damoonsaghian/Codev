apt-get --yes install iwd wireless-regdb bluez rfkill passwd fzy

cp /mnt/system /usr/local/bin/
chmod +x /usr/local/bin/system

echo -n 'unset HISTFILE
export PS1="\e[7m \u@\h \e[0m \e[7m \w \e[0m\n> "
echo "enter \"system\" to configure system settings"
' > /etc/profile.d/shell-prompt.sh

echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.timedate1.set-timezone" &&
		subject.local && subject.active
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-timezone.rules

systemctl enable iwd.service

echo '# allow rfkill for users in the netdev group
KERNEL=="rfkill", MODE="0664", GROUP="netdev"
' >	/etc/udev/rules.d/80-rfkill.rules

echo; echo "setting your timezone"
system timezone

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

# https://www.freedesktop.org/wiki/Software/systemd/inhibit/
echo -n '#!/bin/sh
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
	apt-get --yes --quiet -o Dpkg::Options::=--force-confnew dist-upgrade
}

case "$mode" in
	autoupdate) autoupdate ;;
	update) apt-get update; apt-get dist-upgrade ;;
	install) apt-get install -- "$package_name" ;;
	remove) apt-get purge -- "$package_name" ;;
esac

apt-get --yes --purge autoremove
apt-get --yes autoclean
' > /usr/local/bin/system-packages

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
systemctl enable autoupdate.timer
