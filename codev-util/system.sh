#!/apps/env sh
set -e

# session
# connections
# passwords
# packages: install, remove, update, make a new system)
# backup

# before shutdown/suspend: run "fstrim <mount-point>" for devices supporting unqueued trim
# [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
# [ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -lt 2147483648 ] &&

# https://networkmanager.dev/docs/
# https://networkmanager.dev/docs/api/latest/nmcli.html
# https://wiki.archlinux.org/index.php/NetworkManager

# WIFI using nmcli:
# ; nmcli dev wifi
# ; nmcli --ask dev wifi con <ssid>
# to disconnect from a WIFI network:
# ; nmcli con down id <ssid>

# nmcli connection add olpc-mesh
# https://wiki.archlinux.org/title/Ad-hoc_networking
# can actually replace both hotspot and wifi-p2p (wifi direct)
# nmcli device wifi hotspot
# 	https://wiki.archlinux.org/title/NetworkManager#Sharing_internet_connection_over_Wi-Fi
# nmcli connection add wifi-p2p

# home dir backup is done on a LUKS encrypted BTRFS formated device using btrfs send/receive
# https://wiki.tnonline.net/w/Btrfs/Send
# use the luks header of root device
# luksHeaderBackup <device> --header-backup-file <file>
# luksHeaderRestore <device> --header-backup-file <file>
#
# when a backup device is connected run backup automatically
# show the procedure in status bar
#
# backup procedure:
# decrypt (/var/luks/key) and mount the storage device, then sync it with home dir
# notes:
# if there is not enough space, try to backup the most number of projects possible
# each time a new backup is created, the number stored in .data/backups will be increased
# this number will be decreased when removing a project from backup
# when creating a new backup, the projects with least number of backups will take priority
# do not follow mounts
# in case of bit rot, try to repair
#
# when restoring a backup, check its gnunet url, and download and merge that, if it's newer
#
# backup through gnunet F2F
# there is a timer that automatically syncs project groups, through this F2F network

if [ -z "$1" ];then
	menu() {
		printf "$1" | fzy
	}
elif [ "$1" = ext-menu ]; then
	menu() {
		printf "$1"
		read -r answer
		printf "$answer"
	}
else
	echo "usage: system [swapp]"
	exit 1
fi

manage_session() {
	selected_entry="$(menu "lock\nsuspend\nexit\nreboot\npoweroff")"
	case "$selected_entry" in
	lock) ;;
	exit) ;;
	reboot) doas dinit-reboot ;;
	poweroff) doas dinit-poweroff ;;
	suspend)
		# if swap file's size is not enough, ask for increase
		# first lock then
		doas zzz ;;
	esac
}

manage_wifi() {
	local mode="$(menu "connect\nremove")" device= ssid= answer=
	
	if [ "$mode" = connect ]; then
		echo 'select a device:'
		device_list="$(iwctl device list | tail --line=+5 | cut -c 7-)"
		device="$(menu "$device_list" | { read -r first _; echo "$first"; })"
		
		iwctl station "$device" scan
		echo 'select a network to connect:'
		ssid_list="$(iwctl station "$device" get-networks | tail --line=+5 | cut -c 7-)"
		ssid="$(menu "$ssid_list" | { read -r first _; echo "$first"; })"
		iwctl station "$device" connect "$ssid"
	fi
	
	if [ "$mode" = remove ]; then
		echo 'select a network to remove:'
		ssid_list="$(iwctl known-networks list | tail --line=+5 | cut -c 7-)"
		ssid="$(menu "$ssid_list" | { read -r first _; echo "$first"; })"
		
		echo "remove \"$ssid\"?"
		answer="$(menu "no\nyes")"
		[ "$answer" = yes ] || exit
		
		doas iwctl known-networks "$ssid" forget
	fi
}

manage_cell() {
	echo "not yet implemented"
}

# use nmcli for bluetooth connection or:
# https://wiki.alpinelinux.org/wiki/Bluetooth#Pairing_with_bluetoothctl
manage_bluetooth() {
	local mode= device=
	
	echo "not yet implemented"; exit
	# https://forum.endeavouros.com/t/how-to-script-bluetoothctl-commands/18225/10
	# https://gist.github.com/RamonGilabert/046727b302b4d9fb0055
	# "echo '' | ..." or expect
	#
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/simple-agent
	# https://ukbaz.github.io/howto/python_gio_1.html
	# https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/device-api.txt
	
	mode="$(menu "add\nremove")"
	
	if [ "$mode" = remove ]; then
		bluetoothctl scan on &
		sleep 3
		echo "select a device:"
		device_list="$(bluetoothctl devices)"
		device="$(menu "$device_list" | { read -r _first mac_address; echo "$mac_address"; })"
		
		if bluetoothctl --agent -- pair "$device"; then
			bluetoothctl trust "$device"
			bluetoothctl connect "$device"
		else
			bluetoothctl untrust "$device"
		fi
	fi
	
	if [ "$mode" = remove ]; then
		echo "select a device:"
		device_list="$(bluetoothctl devices)"
		device="$(menu "$device_list" | { read -r _first mac_address; echo "$mac_address"; })"
		doas bluetoothctl disconnect "$device"
		doas bluetoothctl untrust "$device"
	fi
}

manage_radio_devices() {
	# wifi, cellular, bluetooth, gps
	local lines= device= action=
	
	lines="$(rfkill -n -o "TYPE,SOFT,HARD")"
	lines="$(printf "all\n%s" "$lines")"
	echo 'select a radio device:'
	device="$(menu "$lines" | cut -d " " -f1)"

	action="$(menu "block\nunblock")"
	doas rfkill "$action" "$device"
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
	# activate AP mode on it, using iwd
	# http://blog.hoxnox.com/gentoo/wifi-hotspot.html
	# https://wiki.alpinelinux.org/wiki/Wireless_AP_with_udhcpd_and_NAT
	# when removing a wireless device, disable AP mode, and delete the virtual device (if any)
	
	#echo -n '[Match]
	#Type=wlan
	#WLANInterfaceType=ap
	#[Network]
	#Address=0.0.0.0/24
	#DHCPServer=yes
	#IPMasquerade=both
	#' > /etc/systemd/network/80-wifi-ap.network
	# https://hackaday.io/project/162164/instructions?page=2
	# https://raspberrypi.stackexchange.com/questions/133403/configure-usb-wi-fi-dongle-as-stand-alone-access-point-with-systemd-networkd
	# https://man.archlinux.org/man/core/systemd/systemd.netdev.5.en
}

# VPN
# https://fedoramagazine.org/systemd-resolved-introduction-to-split-dns/
# https://blogs.gnome.org/mcatanzaro/2020/12/17/understanding-systemd-resolved-split-dns-and-vpn-configuration/

local selected_option="$(menu "WiFi\ncellular\nBluetooth\nradio\nrouter")"
case "$selected_option" in
WiFi) manage_wifi ;;
cellular) manage_cell ;;
Bluetooth) manage_bluetooth ;;
radio) manage_radio_devices ;;
router) manage_router ;;
esac

set_timezone() {
	# if there is a modem
	if []; then
		# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/gdbus-org.freedesktop.ModemManager1.Modem.Time.html
		# https://lazka.github.io/pgi-docs/ModemManager-1.0/classes/NetworkTimezone.html
		net_tz_offset=
		net_tz="$(tz "$offset")"
	else
		net_tz="$(curl --silent 'http://ip-api.com/line/?fields=timezone')"
	fi
	
	net_tz_continent="$(echo "$net_tz" | cut -d / -f1)"
	net_tz_city="$(echo "$net_tz" | cut -d / -f2)"
	
	# show the list produced by "tz continents"; select $tz_net_continent as default
	continet=
	# show the list produced by "tz city $continent"; select $net_tz_city as default
	city=
	tz set "$continent/$city"
}

set_password() {
	# user password, root password, root encryption password
	# use "sudo passwd home", because we do not want to use PAM support of passwd
}

echo 'packages:'
mode="$(menu "upgrade\nremove\ninstall SPM Linux")"

# doas spm

# if the content of "$spm_dir/status" is "error", turn "packages" and the "update" item under it, red

# add section: some suggested apps like termulator

# sandbox <command>
# run command as user 65534 (nobody)

[ "$mode" = remove ] && {
	package_name_list="$(apt-cache search --names-only "^ospkg-$(id -u)--.*" | sed s/^.*--//)"
	package_name="$(menu "$package_name_list" | { read -r first _rest; echo "$first"; })"
	printf "remove \"$package_name\"?"
	answer="$(menu "no\nyes")"
	[ "$answer" = yes ] || exit
}
spm "$mode" "$package_name" "$package_name"

[ "$mode" = "install SPM Linux" ] && # if not already running, create a gtkvte and run: spm spmlinux
