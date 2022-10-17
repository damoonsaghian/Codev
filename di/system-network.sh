set -e

# https://iwd.wiki.kernel.org/
setup_wifi() {
  choose mode "connect\nremove"
  if [ "$mode" = remove ]; then
    echo 'select a network to remove:'
    choose ssid "$(iwctl known-networks list)"
    ssid="$(echo "$ssid" | cut -c5- | cut -d ' ' -f1)"

    printf "remove $ssid (y/N)? "
    read -r answer
    [ "$answer" = y ] || exit

    iwctl known-networks "$ssid" forget
    exit
  fi

  echo 'select a device:'
  device="$(iwctl device list)"
  device="$(echo "$device" | { read first _; echo $first; })"

  echo 'select a network to connect:'
  choose ssid "$(iwctl station "$device" scan; iwctl station "$device" get-networks)"
  ssid="$(echo "$ssid" | cut -c5- | cut -d ' ' -f1)"
  iwctl station "$device" connect "$ssid"
}

# wifi access point
# https://iwd.wiki.kernel.org/ap_mode
# https://man.archlinux.org/man/community/iwd/iwd.ap.5.en
# https://wiki.archlinux.org/title/software_access_point
# https://hackaday.io/project/162164/instructions?page=2
# https://raspberrypi.stackexchange.com/questions/133403/configure-usb-wi-fi-dongle-as-stand-alone-access-point-with-systemd-networkd
setup_access_point() {
  echo "not yet implemented"
}

# internet sharing
# https://dabase.com/blog/2012/Sharing_an_Internet_connection_in_Archlinux/
# https://wiki.archlinux.org/title/Router
# https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#veth
# https://man.archlinux.org/man/core/systemd/systemd.netdev.5.en
# https://man.archlinux.org/man/core/systemd/systemd.network.5.en
setup_router() {
  echo "not yet implemented"
}

# https://wiki.archlinux.org/title/Mobile_broadband_modem
# https://man.archlinux.org/man/extra/modemmanager/mmcli.1.en
# https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wwan.network
# https://github.com/systemd/systemd/issues/20370
setup_cell() {
  echo "not yet implemented"
}

choose selected_option "wifi\naccess-point\nrouter\ncellular"

case "$selected_option" in
  wifi) setup_wifi ;;
  access-point) setup_access_point ;;
  router) setup_router ;;
  cellular) setup_cell ;;
esac
