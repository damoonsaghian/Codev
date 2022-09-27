set -e

# https://iwd.wiki.kernel.org/
setup_wifi () {
  mode="$(printf "connect\nremove\n" | bemenu -p system/network)"
  if [ "$mode" = remove ]; then
    ssid="$(iwctl known-networks list | tail -n +5 | bemenu -p system/network -l 20 | cut -c5- | cut -d ' ' -f1)"
    iwctl known-networks "$ssid" forget
    exit
  fi
  device="$(iwctl device list | tail -n +5 | bemenu -p system/network -l 20 | { read first _; echo $first; })"
  
  ssid="$({ iwctl station "$device" scan; iwctl station "$device" get-networks; } |
    tail -n +5 | bemenu -p system/network -l 20 | cut -c5- | cut -d ' ' -f1)"
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

selected_option="$(printf "wifi\naccess-point\nrouter\ncellular\n" | bemenu -p system/network)"

case "$selected_option" in
  wifi) setup_wifi ;;
  access-point) setup_access_point ;;
  router) setup_router ;;
  cellular) setup_cell ;;
esac
