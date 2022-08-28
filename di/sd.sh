apt-get install --no-install-recommends --yes dosfstools exfatprogs btrfs-progs udisks2 polkitd

cat <<'_EOF_' > /usr/local/share/sd.sh
set -e

# storage device manager, using udisks2 dbus interface
# https://www.freedesktop.org/wiki/Software/dbus/
# https://dbus.freedesktop.org/doc/dbus-tutorial.html

format () {
  # http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Drive.html#gdbus-property-org-freedesktop-UDisks2-Drive.Removable
  removable=
  if [ "$removable" = "true" ]; then
    # format with VFAT (or exFAT if there would be files bigger than 4GB)
    # http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
  else
    pkexec sh /usr/local/share/sd-internal.sh format "$1"
  fi
}

mount () {
  removable=
  if [ "$removable" = "true" ]; then
    udisksctl mount -b /dev/"$1"
  else
    pkexec sh /usr/local/share/sd-internal.sh mount "$1"
  fi
}

unmount () {
  udisksctl unmount -b /dev/"$1"
}

write_image () {
  # http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.OpenDevice
  # the set of file descriptors open in a process can be accessed under the path /proc/PID/fd/,
  #   where PID is the process identifier
  image_file="$1"
  device_name="$2"
}

case "$1" in
  format) shift; format "$@" ;;
  mount) shift; mount "$@" ;;
  unmount) shift; unmount "$@" ;;
  write) shift; write_image "$@" ;;
  *) echo 'usage: sd format/mount/unmount/write'
    exit 1 ;;
esac
_EOF_

cat <<'_EOF_' > /usr/local/share/sd-internal.sh
set -e
format () {
  # if it is not already formated with BTRFS
  mkfs.btrfs /dev/"$1"
}
mount () {
  mkdir -p /run/mount/"$1"
  mount -o noexec,nosuid,nodev /dev/$1 /run/mount/"$1"
  cp --no-clobber --preserve=all /home/ /run/mount/"$1"
}
case "$1" in
  format) shift; format "$@" ;;
  mount) shift; mount "$@" ;;
  *) echo "usage: sd-internal format/mount"
    exit 1 ;;
esac
_EOF_

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.sd.sd-internal">
    <description>internal storage device management</description>
    <message>internal storage device management</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sd-internal</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.sd.policy

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[udisks]
# write disk images, on non-system devices, without asking for password
Identity=unix-user:*
Action=org.freedesktop.udisks2.open-device
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/comshell.sd.pkla
