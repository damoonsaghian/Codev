choose() {
	# the list of choices with the indents removed
	local list="$(echo "$2" | sed -r 's/^[[:blank:]]+//')"
	local count="$(echo "$2" | wc -l)"
	local index=1
	local key=
	
	local terminal_height="$(stty size | cut -d ' ' -f1)"
	local max_height=15
	[ $max_height -gt $terminal_height ] && max_height=$terminal_height
	local scrolled=false
	[ $((count+2)) -gt $max_height ] && scrolled=true
	
	# if a default option is provided, find its index
	[ -z "$3" ] || {
		i="$(printf "$list" | sed -n "/$3/=" | head -n 1)"
		[ -z "$i" ] || index=i
	}
	
	while true; do
		# print the lines, highlight the selected one
		printf "$list" | {
			i=1
			j=$((index-max_height/2))
			while read line; do
				d=$((i-index))
				$scrolled && { [ $i -lt $j ] || [ $i -gt $((j+max_height-2)) ]; } && break
				
				if [ $i = $index ]; then
					printf "  \e[7m$line\e[0m\n" # highlight
				else
					printf "  $line\n"
				fi
				i=$((i+1))
			done
		}

		if [ $index -eq 0 ]; then
			printf "\e[7mexit\e[0m\n" # highlighted
		else
			printf "\e[8mexit\e[0m\n" # hidden
		fi
		
		read -s -n1 key # wait for user to press a key
		
		# if key is empty, it means the read delimiter, ie the "enter" key was pressed
		[ -z "$key" ] && break

		if [ "$key" = "\177" ]; then
			index=0
		elif [ "$key" = " " ]; then
			index=$((index+1))
			[ $index -gt $count ] && i=1
		else
			# find the next line which its first character is "$key", and put the line's number in "index"
			i=index
			while true; do
				i=$((i+1))
				[ $i -gt $count ] && i=1
				[ $i -eq $index ] && break
				if [ "$(echo "$list" | sed -n "$i"p | cut -c1)" = "$key" ]; then
					index=i
					break
				fi
			done
		fi
		
		if $scrolled; then
			echo -en "\e[$((max_height-1))A"
		else
			echo -en "\e[$((count+1))A" # go up to the beginning to re'render
		fi
	done
	
	[ $index -eq 0 ] && { echo; exit; }
	selected_line="$(echo "$list" | sed -n "${index}p")"
	eval "$1=\"$selected_line\""
}

# guess time'zone but let the user confirm it
set_timezone() {
	local auto_timezone="$(wget -q -O- 'http://ip-api.com/line/?fields=timezone')"
	local auto_continent="$(printf "$auto_timezone" | cut -d / -f1)"
	local auto_city="$(printf "$auto_timezone" | cut -d / -f2)"
	
	choose continent "$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5)" $auto_continent
	choose city "$(ls -1 /usr/share/zoneinfo/"$continent"/* | cut -d / -f6)" $auto_city
	tzset "${continent}/${city}"
}

# https://docs.alpinelinux.org/user-handbook/0.1a/Working/apk.html
# https://wiki.alpinelinux.org/wiki/Alpine_Package_Keeper
# https://www.reddit.com/r/AlpineLinux/comments/y6ezvo/interactive_installationremoval_of_packages_using/
manage_packages() {
	local mode= package_name=
	echo 'packages:'
	choose mode 'update\ninstall\nremove'
	[ "$mode" = install ] && {
		printf 'search for: '
		read -r search_entry
		choose package_name "$(apk search "$search_entry")"
		package_name="$(echo "$package_name" | { read first _rest; echo $first; })"
	}
	[ "$mode" = remove ] && {
		printf 'search for: '
		read -r search_entry
		choose package_name "$(apk search "$search_entry")"
		package_name="$(echo "$package_name" | { read first _rest; echo $first; })"
		printf "remove $package_name (y/N)? "
		read -r answer
		[ "$answer" = y ] || exit
	}
	
	if [ "$mode" = "autoupdate" ]; then
		critical_battery() {
			local battery_capacity="/sys/class/power_supply/BAT0/capacity"
			[ -f "$battery_capacity" ] || battery_capacity="/sys/class/power_supply/BAT1/capacity"
			[ -f "$battery_capacity" ] && [ "$(cat "$battery_capacity")" -le 20 ]
		}
		
		metered_connection() {
			local active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
			local is_metered=false
			case "$active_net_device" in
				ww*) is_metered=true ;;
			esac
			# todo: DHCP option 43 ANDROID_METERED
			is_metered
		}
		
		critical_battery || metered_connection && exit 0
	fi
	
	manage-packages "$mode" "$package_name"
}

# https://wiki.alpinelinux.org/wiki/Wi-Fi
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
	doas /usr/sbin/rfkill "$action" "$device"
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
