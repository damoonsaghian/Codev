set -e

# https://www.debian.org/doc/manuals/apt-guide/index.en.html
# https://www.debian.org/doc/manuals/apt-offline/index.en.html
# https://github.com/cmuench/pacman-auto-update/blob/master/root/usr/lib/pacman-auto-update/pacman-auto-update

[ "$1" = "install-firmware" ] && {
  device_name="$2"
  # find and install required firmwares
  # https://salsa.debian.org/debian/isenkram
  exit
}

apm_mode=install
# ask user to enter a word to search for packages
# leave it empty to just do an upgrade
# https://manpages.debian.org/bullseye/apt/apt-cache.8.en.html
apm_mode=update
# ask user to enter the names of packages
package_names=
# if all of the entered packages are already installed, ask the user if she wants to remove them
# https://manpages.debian.org/bullseye/dpkg/dpkg-query.1.en.html
apm_mode=remove

[ "$1" = "autoupdate" ] && apm_mode=autoupdate

critical_battery() {
  battery_capacity="/sys/class/power_supply/BAT0/capacity"
  [ -f "$battery_capacity" ] || battery_capacity="/sys/class/power_supply/BAT1/capacity"
	[ -f "$battery_capacity" ] && [ "$(cat "$battery_capacity")" -le 20 ]
}
metered_connection() {
  # nmcli --terse --fields GENERAL.METERED dev show | grep --quiet "yes"
  # if not mobile broadband
	true
}
[ "$1" = "autoupdate" ] && { critical_battery || metered_connection; } && exit 0

[ -f /tmp/apm-lock ] && {
  echo 'another instance is running; wait for it to finish, or reboot the system'
  exit 1
}
trap "rm -f /tmp/apm-lock; trap - EXIT; exit" EXIT HUP INT QUIT ABRT TERM
touch /tmp/apm-lock

old_snapshot="$(realpath /0)"
if [ "$old_snapshot" = "/1" ]; then
  new_snapshot="/2"
else
  new_snapshot="/1"
fi

[ -d "$new_snapshot" ] && btrfs subvolume delete "$new_snapshot"

btrfs subvolume create "$new_snapshot"
btrfs subvolume snapshot "$old_snapshot" "$new_snapshot"

mount --bind /etc "$new_snapshot"/etc
mount --bind /home "$new_snapshot"/home
mount --bind /root "$new_snapshot"/root
mount --bind /opt "$new_snapshot"/opt
mount --bind /usr/local "$new_snapshot"/usr/local
mount --bind /srv "$new_snapshot"/srv
mount --bind /tmp "$new_snapshot"/tmp
mount --bind /var "$new_snapshot"/var
mount --bind /boot/efi "$new_snapshot"/boot/efi

# fork this; long running swapps commands
chroot "$new_snapshot" /usr/bin/sh -c 'set -e
apt-get update
case "$1" in
  remove) shift; apt-get purge -- "$@" ;;
  install) shift; apt-get install --no-install-recommends -- "$@" ;;
  update) apt-get dist-upgrade ;;
  autoupdate) apt-get dist-upgrade --yes ;;
esac
apt-get autoremove --purge --yes
apt-get autoclean --yes
bootctl update --graceful --quiet --no-variables --esp-path=/boot/efi' apm "$apm_mode" "$package_names"

ln --symbolic --force -T "$new_snapshot" /3
mv --force -T /3 /0
