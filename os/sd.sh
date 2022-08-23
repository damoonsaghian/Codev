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