apt-get install --no-install-recommends --yes dosfstools exfatprogs btrfs-progs udisks2

echo -n '#!/usr/bin/pkexec /bin/sh
mkdir -p /run/mount/"$1"
result=$"(findmnt --mountpoint /run/mount/"$1")"
[ -z "$result" ] && mount -o nosuid,nodev,noexec,nofail /dev/$1 /run/mount/"$1"
cp --no-clobber --preserve=all /home/ /run/mount/"$1"
' > /usr/local/bin/sd-internal
chmod +x /usr/local/bin/sd-internal

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.sd.internal">
    <description>internal storage device management</description>
    <message>internal storage device management</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sd-internal</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.sd.policy

cp /mnt/comshell/di/sd-write /usr/local/bin/

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[udisks]
# write disk images, on non-system devices, without asking for password
Identity=unix-user:*
Action=org.freedesktop.udisks2.open-device
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/comshell.sd.pkla
