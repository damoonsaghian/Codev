# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/
# https://wiki.archlinux.org/title/ConnMan
# https://github.com/liamw9534/pyconnman

# todo: set "TimezoneUpdates" to "auto" using the dbus api:
# https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/clock-api.txt

# https://wiki.alpinelinux.org/wiki/Wi-Fi
# https://pkgs.alpinelinux.org/package/edge/community/x86_64/ofono

# https://iwd.wiki.kernel.org/
setup_wifi() {
	pick mode "connect\nremove"
	if [ "$mode" = remove ]; then
		echo 'select a network to remove:'
		pick ssid "$(iwctl known-networks list)"
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
	pick ssid "$(iwctl station "$device" scan; iwctl station "$device" get-networks)"
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
# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/
# https://man.archlinux.org/man/extra/modemmanager/mmcli.1.en
# https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wwan.network
# https://github.com/systemd/systemd/issues/20370
setup_cell() {
	echo "not yet implemented"
}

setup_bluetooth() {
	echo "not yet implemented"; exit
	
	# https://forum.endeavouros.com/t/how-to-script-bluetoothctl-commands/18225/10
	# https://gist.github.com/RamonGilabert/046727b302b4d9fb0055
	# "echo '' | ..." or expect
	
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/simple-agent
	# https://ukbaz.github.io/howto/python_gio_1.html
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/device-api.txt

	pick mode "add\nremove"
	
	if [ "$mode" = remove ]; then
		echo "select a device:"
		pick device "$(bluetoothctl devices)"
		device="$(echo "$device" | { read _first mac_address; echo $mac_address; })"
		bluetoothctl disconnect "$device"
		bluetoothctl untrust "$device"
		exit
	fi
	
	bluetoothctl scan on &
	sleep 3
	echo "select a device:"
	pick device "$(bluetoothctl devices)"
	device="$(echo "$device" | { read _first mac_address; echo $mac_address; })"
	
	if bluetoothctl --agent -- pair "$device"; then
		bluetoothctl trust "$device"
		bluetoothctl connect "$device"
	else
		bluetoothctl untrust "$device"
	fi
}

configure_radio_devices() {
	# wifi, cellular, bluetooth, gps
	local lines="all\n$(rfkill -n -o "TYPE,SOFT,HARD")"
	echo 'select a radio device:'
	pick device "$lines"
	device="$(printf "$device" | cut -d " " -f1)"
	echo "$device:"
	pick action "block\nunblock"
	doas /usr/sbin/rfkill "$action" "$device"
}

pick selected_option "wifi\naccess-point\nrouter\ncellular\nbluetooth\nradio"

case "$selected_option" in
	wifi) setup_wifi ;;
	access-point) setup_access_point ;;
	router) setup_router ;;
	cellular) setup_cell ;;
	bluetooth) setup_bluetooth ;;
	radio) configure_radio_devices ;;
esac
