# https://wiki.alpinelinux.org/wiki/Wi-Fi
# wpa_supplicant
manage_wifi() {
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

manage_cell() {
	echo "not yet implemented"
}

manage_bluetooth() {
	echo "not yet implemented"; exit
	
	# https://forum.endeavouros.com/t/how-to-script-bluetoothctl-commands/18225/10
	# https://gist.github.com/RamonGilabert/046727b302b4d9fb0055
	# "echo '' | ..." or expect
	
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/simple-agent
	# https://ukbaz.github.io/howto/python_gio_1.html
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/device-api.txt

	choose mode "add\nremove"
	
	if [ "$mode" = remove ]; then
		echo "select a device:"
		choose device "$(bluetoothctl devices)"
		device="$(echo "$device" | { read _first mac_address; echo $mac_address; })"
		bluetoothctl disconnect "$device"
		bluetoothctl untrust "$device"
		exit
	fi
	
	bluetoothctl scan on &
	sleep 3
	echo "select a device:"
	choose device "$(bluetoothctl devices)"
	device="$(echo "$device" | { read _first mac_address; echo $mac_address; })"
	
	if bluetoothctl --agent -- pair "$device"; then
		bluetoothctl trust "$device"
		bluetoothctl connect "$device"
	else
		bluetoothctl untrust "$device"
	fi
}

manage_radio_devices() {
	# wifi, cellular, bluetooth, gps
	local lines="all\n$(rfkill -n -o "TYPE,SOFT,HARD")"
	echo 'select a radio device:'
	choose device "$lines"
	device="$(printf "$device" | cut -d " " -f1)"
	echo "$device:"
	choose action "block\nunblock"
	pkexec /usr/sbin/rfkill "$action" "$device"
}

manage_router() {
	echo "not yet implemented"
	
	# https://wiki.archlinux.org/title/Router
	# https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#veth
	
	# ask for add/remove
	# if remove:
	# , show the out devices
	# , ask for the name of devices (or all)
	# , remove the devices from ifupdown-ng config, and from Connman unmanaged
	# if add:
	# , ask for the name of devices to add
	# , put the devices in connman unmanaged
	# , install busybox-extras (for udhcpd)
	# , run a dhcp server on them, using ifupdown-ng (https://github.com/ifupdown-ng/ifupdown-ng/tree/main/doc)
	
	# if the device is a wireless LAN (ie we want a wifi access point)
	# if there is only one wifi device, create a virtual one (concurrent AP-STA mode)
	# https://wiki.archlinux.org/title/software_access_point
	# https://variwiki.com/index.php?title=Wifi_NetworkManager#WiFi_STA.2FAP_concurrency
	# put this virtual wifi device in connman unmanaged
	# activate AP mode on it, using wpa_supplicant
	# http://blog.hoxnox.com/gentoo/wifi-hotspot.html
	# run a dhcp server on it, using ifupdown-ng
	# https://wiki.alpinelinux.org/wiki/Wireless_AP_with_udhcpd_and_NAT
	# when removing a wireless device, disable AP mode, and delete the virtual device (if any)
}

manage_connections() {
	choose selected_option "wifi\naccess-point\nrouter\ncellular\nbluetooth\nradio"
	case "$selected_option" in
		wifi) manage_wifi ;;
		cellular) manage_cell ;;
		bluetooth) manage_bluetooth ;;
		radio) manage_radio_devices ;;
		router) manage_router ;;
	esac
}
