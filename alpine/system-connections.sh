set -e

# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/
# https://wiki.archlinux.org/title/ConnMan
# https://github.com/liamw9534/pyconnman

# todo: set "TimezoneUpdates" to "auto" using the dbus api:
# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/clock-api.txt

# https://wiki.alpinelinux.org/wiki/Wi-Fi
# https://pkgs.alpinelinux.org/package/edge/community/x86_64/ofono

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

setup_bluetooth() {
	# the correct usage domain for Bluetooth is personal devices like headsets
	# it perfectly makes sense to pair them per user
	# since keyboards are used for login, they must be paired globally
	# still, even pairing of keyboards doesn't need root access
	# because in this system, when a keyboard is connected, others are disabled, and current session gets locked
	
	# Bluetooth keyboards must have an already paired Bluetooth dongle, or an additional USB connection
}

configure_radio_devices() {
	# wifi, cellular, bluetooth, gps
	lines="all\n$(rfkill -n -o "TYPE,SOFT,HARD")"
	echo 'select a radio device:'
	choose device "$lines"
	device="$(printf "$device" | cut -d " " -f1)"
	echo "$device:"
	choose action "block\nunblock"
	doas /usr/sbin/rfkill "$action" "$device"
}

choose selected_option "wifi\naccess-point\nrouter\ncellular\nbluetooth\nradio"

case "$selected_option" in
	wifi) setup_wifi ;;
	access-point) setup_access_point ;;
	router) setup_router ;;
	cellular) setup_cell ;;
	bluetooth) setup_bluetooth ;;
	radio) configure_radio_devices ;;
esac
