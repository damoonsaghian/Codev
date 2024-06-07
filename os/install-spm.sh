apt-get -qq install gnunet

useradd --system spm
mkdir -p /var/spm
chown spm /var/spm

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="local.pkexec.spm">
		<description>spm</description>
		<message>spm</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/bash</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/spm</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/local.pkexec.spm.policy

cp /mnt/os/spm.sh /usr/local/bin/spm
chmod +x /usr/local/bin/spm

mkdir -p /usr/local/lib/systemd/user
echo -n '[Unit]
Description=automatic update
ConditionACPower=true
After=network-online.target
[Service]
Type=oneshot
ExecStartPre=-/usr/lib/apt/apt-helper wait-online
ExecStart=/usr/local/bin/spm autoupdate
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
systemctl --global enable spm-autoupdate.timer

mkdir -p /usr/local/lib/systemd/system
cp /usr/local/lib/systemd/user/spm-autoupdate.service /usr/local/lib/systemd/system/spm-autoupdate.service
cp /usr/local/lib/systemd/user/spm-autoupdate.timer /usr/local/lib/systemd/system/spm-autoupdate.timer
systemctl enable spm-autoupdate.timer
