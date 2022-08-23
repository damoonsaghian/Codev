set -e

# https://iwd.wiki.kernel.org/
setup_wifi () {
  printf "do you want to forget a known network (y/N): "
  read -r forget_mode
  if [ "$forget_mode" = y ]; then
    iwctl known-networks list
    printf "select a known network to forget: "
    read -r ssid
    iwctl known-networks "$ssid" forget
    exit
  fi
  iwctl device list
  printf "select a device: "
  read -r device
  iwctl station "$device" scan
  iwctl station "$device" get-networks
  printf "select a network: "
  read -r ssid
  iwctl station "$device" connect "$ssid"
}

# wifi access point
# https://iwd.wiki.kernel.org/ap_mode
# https://man.archlinux.org/man/community/iwd/iwd.ap.5.en
# https://wiki.archlinux.org/title/software_access_point
# https://hackaday.io/project/162164/instructions?page=2
# https://raspberrypi.stackexchange.com/questions/133403/configure-usb-wi-fi-dongle-as-stand-alone-access-point-with-systemd-networkd
setup_access_point () {
  echo "not yet implemented"
}

# internet sharing
# https://dabase.com/blog/2012/Sharing_an_Internet_connection_in_Archlinux/
# https://wiki.archlinux.org/title/Router
# https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#veth
# https://man.archlinux.org/man/core/systemd/systemd.netdev.5.en
# https://man.archlinux.org/man/core/systemd/systemd.network.5.en
setup_router () {
  echo "not yet implemented"
}

# https://wiki.archlinux.org/title/Mobile_broadband_modem
# https://man.archlinux.org/man/extra/modemmanager/mmcli.1.en
# https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wwan.network
# https://github.com/systemd/systemd/issues/20370
setup_cell () {
  echo "not yet implemented"
}

echo -n "
, wifi
, access-point
, router
, cellular
select one by typing the first charactor at the least (wifi is default): "
read -r selected_option

case "$selected_option" in
  a*) setup_access_point ;;
  r*) setup_router ;;
  c*) setup_cell ;;
  *) shift; setup_wifi "$@" ;;
esac
