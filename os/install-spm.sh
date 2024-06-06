echo -n '[Unit]
Description=automatic update
ConditionACPower=true
After=network-online.target
[Service]
Type=oneshot
ExecStartPre=-/usr/lib/apt/apt-helper wait-online
ExecStart=/usr/local/bin/spm update
KillMode=process
TimeoutStopSec=900
Nice=19
' > /usr/local/lib/systemd/user/spm-autoupdate.service

echo -n '[Unit]
Description=automatic update
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/user/spm-autoupdate.timer

systemctl --global enable spm.timer

cp /mnt/os/spm-os.sh /usr/local/bin/spm-os
chmod +x /usr/local/bin/spm-os

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="local.pkexec.spm">
		<description>upm</description>
		<message>upm</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/bash</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/spm</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/local.pkexec.upm.policy

mkdir -p /usr/local/lib/systemd/system

echo -n '[Unit]
Description=automatic update
ConditionACPower=true
After=network-online.target
[Service]
Type=oneshot
ExecStartPre=-/usr/lib/apt/apt-helper wait-online
ExecStart=/usr/local/bin/upm auto-upgrade
KillMode=process
TimeoutStopSec=900
Nice=19
' > /usr/local/lib/systemd/system/upm-auto-upgrade.service

echo -n '[Unit]
Description=automatic update
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/upm-auto-upgrade.timer

systemctl enable upm-auto-upgrade.timer
