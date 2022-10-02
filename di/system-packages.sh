set -e

# https://www.debian.org/doc/manuals/apt-guide/index.en.html
# https://www.debian.org/doc/manuals/apt-offline/index.en.html
# https://github.com/cmuench/pacman-auto-update/blob/master/root/usr/lib/pacman-auto-update/pacman-auto-update

[ -f /tmp/apm-lock ] && {
  echo 'another instance is running; wait for it to finish, or reboot the system'
  exit 1
}
trap "rm -f /tmp/apm-lock; trap - EXIT; exit" EXIT HUP INT QUIT ABRT TERM
touch /tmp/apm-lock

[ "$1" = "install-firmware" ] && {
  device_name="$2"
  # find and install required firmwares
  # https://salsa.debian.org/debian/isenkram
  exit
}

if [ "$1" = "autoupdate" ]; then
  critical_battery() {
    battery_capacity="/sys/class/power_supply/BAT0/capacity"
    [ -f "$battery_capacity" ] || battery_capacity="/sys/class/power_supply/BAT1/capacity"
  	[ -f "$battery_capacity" ] && [ "$(cat "$battery_capacity")" -le 20 ]
  }
  
  metered_connection() {
    active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
    is_metered=false
  	case "$active_net_device" in
      ww*) is_metered=true ;;
    esac
    # todo: DHCP option 43 ANDROID_METERED
    is_metered
  }
  
  critical_battery || metered_connection && exit 0
  mode=update
else
  mode="$(printf 'update\ninstall\nremove\n' | bemenu -p 'system/packages')"
  [ "$mode" = install ] && {
    search_entry="$(echo | bemenu -p 'system/packages/install')"
    package_name="$(
      { apt-get update --yes; apt-cache search "$search_entry"; } |
      bemenu -p system/packages/install -l 30 |
      { read first _rest; echo $first; }
    )"
  }
  
  [ "$mode" = remove ] && {
    search_entry="$(echo | bemenu -p 'system/packages/remove')"
    package_name="$(
      { apt-get update --yes; apt-cache search "$search_entry"; } |
      bemenu -p system/packages/remove -l 30 |
      { read first _rest; echo $first; }
    )"
    confirm_remove="$(printf "no\nyes" | bemenu -p "system/packages/remove($package_name)")"
    [ "$confirm_remove" != yes ] && exit
  }
fi

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

chroot "$new_snapshot" /usr/bin/sh -c 'set -e
case "$1" in
  update) apt-get update --yes; apt-get dist-upgrade --yes ;;
  install) apt-get install --no-install-recommends --yes -- "$2" ;;
  remove) apt-get purge --yes -- "$2" ;;
esac
apt-get autoremove --purge --yes
apt-get autoclean --yes
bootctl update --graceful --quiet --no-variables --esp-path=/boot/efi' apm "$mode" "$package_name"

ln --symbolic --force -T "$new_snapshot" /3
mv --force -T /3 /0
