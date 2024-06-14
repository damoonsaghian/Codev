import subprocess

import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import Gio, Gdk, Gtk

class AppsView(Gtk.Box):
	def __init__(self, **kwargs):
		super().__init__(**kargs)
		self.orientation = Gtk.Orientation.VERTICAL
		self.spacing = 5
		self.margin_top = 5
		self.margin_bottom = 5
		self.margin_start = 5
		self.margin_end = 5
		
		search_entry = Gtk.SearchEntry()
		search_entry.connect('search_changed', on_search_entry_changed)
		search_entry.connect('activate', lambda: raise_or_run_app(apps_list.get_selected()))
		
		self.items_list = Gio.ListStore(Gtk.Application)
		
		self.items_flowbox = Gtk.FlowBox(
			orientation=gtk.Orientation.HORIZONTAL,
			column_spacing=5,
			row_spacing=5,
			margin_top=5, margin_bottom=5, margin_start=5, margin_end=5,
			selection_mode=gtk.SelectionMode.NONE,
			focusable=false
		)
		self.items_flowbox.bind_model(self.items_list, self.create_widget)
		
		self.append(search_entry)
		self.append(Gtk.ScrolledWindow(child=self.items_flowbox))
		
		self.update_apps_list()
		Gio.AppInfoMonitor.get().connect('changed', self.update_apps_list)
	
	def on_search_entry_changed():
		# find and select the first item whose name matches: string:gsub(search_entry.text, " ", ".* ")
	
	def create_widget(app_item):
		label = Gtk.Label(
			label=app_item.get_name(),
			justify=Gtk.Justification.CENTER,
			width_chars=20
		)
		
		icon = Gtk.Image.new_from_gicon(app_item.get_icon())
				
		event_controller = Gtk.EventControllerKey()
		event_controller.connect(
			'key_pressed',
			lambda _, keyval: keyval == Gdk.BUTTON_PRIMARY and self.raise_or_run_app(app_item)
		)
		
		widget = gtk.Box(orientation=gtk.Orientation.VERTICAL, spacing=5)
		widget.append(label)
		widget.append(icon)
		widget.add_controller(event_controller)
		return widget
	
	def raise_or_run_app(app_item):
		os.execute('swaymsg workspace ' .. string.format('%q', app_item:get_name()))
		error_code = os.execute('swaymsg "[con_id=__focused__] focus"')
		if error_code != 0:
			os.execute('swaymsg exec ' .. string.format('%q', app_item:get_commandline()))
		os.execute("swaymsg move scratchpad")
		# swaymsg "[con_id=codev] focus" || python3 /usr/local/share/codev
		# swaymsg "[app_id=codev] move workspace $app; workspace $app"; app.exec
	
	def compare_apps(app1, app2):
		app1_name = app1.get_name()
		app2_name = app2.get_name()
		if app2_name > app1_name:
			return -1
		elif app1_name > app2_name:
			return 1
		else:
			return 0
	
	def update_apps_list():
		apps_list.remove_all()
		for _, app in ipairs(gio.AppInfo.get_all()):
			app_name = app.get_name()
			if app.should_show():
				apps_list.insert_sorted(app, self.compare_apps)

class SystemManagerView(Gtk.Stack):
	def __init__(self, **kargs):
		super().__init__(**kargs)
		self.orientation = Gtk.Orientation.VERTICAL
		
		# two spaces: go back to the previous view

def create_session_manager_view():
	session_manager_list = Gio.ListStore(glib.HashTable)
	filter = Gtk.StringFilter()
	session_manager_list_filtered = Gtk.FilterListModel(session_manager_list, filter)
	
	session_manager_list.insert(
		name='lock',
		icon_name='system-lock-screen-symbolic',
		command='/usr/local/bin/lock'
	)
	session_manager_list.insert(
		name='suspend',
		icon_name='media-playback-pause-symbolic',
		command='systemctl suspend'
	)
	session_manager_list.insert(
		name='exit',
		icon_name='system-log-out-symbolic',
		command='swaymsg exit'
	)
	session_manager_list.insert(
		name='reboot',
		icon_name='system-reboot-symbolic',
		command='systemctl reboot'
	)
	session_manager_list.insert(
		name='poweroff',
		icon_name='system-shutdown-symbolic',
		command='systemctl poweroff'
	)
	
	session_manager_flowbox = Gtk.FlowBox(
		orientation=gtk.Orientation.HORIZONTAL,
		column_spacing=5,
		row_spacing=5,
		margin_top=5, margin_bottom=5, margin_start=5, margin_end=5,
		selection_mode=gtk.SelectionMode.NONE,
		focusable=false
	)
	session_manager_flowbox.bind_model(session_manager_list_filtered, function(sm_item)
		label = Gtk.Label{
			label = sm_item.name,
			justify = gtk.Justification.CENTER,
			width_chars = 20
		}
		
		icon = Gtk.Image.new_from_gicon(sm_item.icon_name)
		
		def on_key_pressed	(_, keyval):
			if keyval == Gdk.BUTTON_PRIMARY:
				os.execute(sm_item.command)
		key_event_controller = Gtk.EventControllerKey()
		key_event_controller.connect('key_pressed', on_key_pressed)
		
		widget = Gtk.Box{
			orientation = gtk.Orientation.VERTICAL,
			spacing = 5
		}
		widget.append(label)
		widget.append(icon)
		widget.add_controller(event_controller)
		return widget
	end)
	
	search_entry = Gtk.SearchEntry()
	
	search_entry.search_changed = function(search_entry)
		filter:set_search(string:gsub(search_entry.text, " ", ".* "))
	end
	
	search_entry.on_activate = function()
		os.execute(session_manager_list_filtered:get_item(0).command)
	end
	
	session_manager_view = Gtk.Box(Gtk.Orientation.VERTICAL, 0)
	session_manager_view.append(search_entry)
	session_manager_view.append(Gtk.ScrolledWindow(child=session_manager_flowbox))
	return session_manager_view

'''
#!/bin/sh
set -e

manage_wifi() {
	local mode="$(printf "connect\nremove" | fzy)" device= ssid= answer=
	# filtered fzy
	local ffzy=""
	
	if [ "$mode" = connect ]; then
		echo 'select a device:'
		device="$(iwctl device list |
			tail --line=+5 | cut -c 7- | fzy | { read -r first _; echo "$first"; })"
		
		iwctl station "$device" scan
		echo 'select a network to connect:'
		ssid="$(iwctl station "$device" get-networks |
			tail --line=+5 | cut -c 7- | fzy | { read -r first _; echo "$first"; })"
		iwctl station "$device" connect "$ssid"
	fi
	
	if [ "$mode" = remove ]; then
		echo 'select a network to remove:'
		ssid="$(iwctl known-networks list |
			tail --line=+5 | cut -c 7- | fzy | { read -r first _; echo "$first"; })"
		
		echo "remove \"$ssid\"?"
		answer="$(printf "no\nyes" | fzy)"
		[ "$answer" = yes ] || exit
		
		iwctl known-networks "$ssid" forget
	fi
}

manage_cell() {
	echo "not yet implemented"
}

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
	
	mode="$(printf "add\nremove" | fzy)"
	
	if [ "$mode" = remove ]; then
		bluetoothctl scan on &
		sleep 3
		echo "select a device:"
		device="$(bluetoothctl devices | fzy | { read -r _first mac_address; echo "$mac_address"; })"
		
		if bluetoothctl --agent -- pair "$device"; then
			bluetoothctl trust "$device"
			bluetoothctl connect "$device"
		else
			bluetoothctl untrust "$device"
		fi
	fi
	
	if [ "$mode" = remove ]; then
		echo "select a device:"
		device="$(bluetoothctl devices | fzy | { read -r _first mac_address; echo "$mac_address"; })"
		bluetoothctl disconnect "$device"
		bluetoothctl untrust "$device"
	fi
}

manage_radio_devices() {
	# wifi, cellular, bluetooth, gps
	local lines= device= action=
	
	lines="$(rfkill -n -o "TYPE,SOFT,HARD")"
	lines="$(printf "all\n%s" "$lines")"
	echo 'select a radio device:'
	device="$(echo "$lines" | fzy | cut -d " " -f1)"

	action="$(printf "block\nunblock" | fzy)"
	rfkill "$action" "$device"
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

manage_connections() {
	local selected_option="$(printf "wifi\ncellular\nbluetooth\nradio\nrouter" | fzy)"
	case "$selected_option" in
		wifi) manage_wifi ;;
		cellular) manage_cell ;;
		bluetooth) manage_bluetooth ;;
		radio) manage_radio_devices ;;
		router) manage_router ;;
	esac
}

set_timezone() {
	# guess the timezone, but let the user to confirm it
	local geoip_tz= geoip_tz_continent= geoip_tz_city= tz_continent= tz_city=
	command -v wget > /dev/null 2>&1 || apt-get -qq install wget > /dev/null 2>&1 || true
	geoip_tz="$(wget -q -O- 'http://ip-api.com/line/?fields=timezone')"
	geoip_tz_continent="$(echo "$geoip_tz" | cut -d / -f1)"
	geoip_tz_city="$(echo "$geoip_tz" | cut -d / -f2)"
	tz_continent="$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5 |
		fzy -p "select a continent: " -q "$geoip_tz_continent")"
	tz_city="$(ls -1 /usr/share/zoneinfo/"$tz_continent"/* | cut -d / -f6 |
		fzy -p "select a city: " -q "$geoip_tz_city")"
	timedatectl set-timezone "${tz_continent}/${tz_city}"
}

change_passwords() {
	local answer="$(printf "user password\nsudo password" | fzy)"
	
	[ "$answer" = "user password" ] && while ! passwd --quiet; do
		echo "an error occured; please try again"
	done
	
	[ "$answer" = "sudo password" ] && while ! sudo passwd --quiet; do
		echo "an error occured; please try again"
	done
}

manage_packages() {
	local mode= package_name= answer=no
	echo 'packages:'
	mode="$(printf "upgrade\nadd\nremove" | fzy)"
	
	[ "$mode" = add ] && {
		printf 'search for: '
		read -r search_entry
		ospkg-deb sync
		package_name="$(apt-cache search "$search_entry" | fzy | { read -r first _rest; echo "$first"; })"
		apt-cache show "$package_name"
		echo "install \"$package_name\"?"
		answer="$(printf "yes\nno" | fzy)"
		[ "$answer" = yes ] || exit
	}
	
	[ "$mode" = remove ] && {
		package_name="$(apt-cache search --names-only "^ospkg-$(id -u)--.*" | sed s/^.*--// |
			fzy | { read -r first _rest; echo "$first"; })"
		printf "remove \"$package_name\"?"
		answer="$(printf "no\nyes" | fzy)"
		[ "$answer" = yes ] || exit
	}
	ospkg-deb "$mode" "$package_name" "$package_name"
}

if [ -z "$1" ]; then
	selected_option="$(printf "connections\ntimezone\npasswords\npackages" | fzy)"
else
	selected_option="$1"
fi

case "$selected_option" in
	connections) manage_connections ;;
	timezone) set_timezone ;;
	passwords) change_passwords ;;
	packages) manage_packages ;;
esac
'''

class MyApp(Gtk.Application):
	def __init__(self, **kwargs):
		super().__init__(**kwargs)
		self.application_id = 'swapps'
		
	def do_startup(self):
		self.root_view = Gtk.Notebook()
		self.root_view.append_page(AppsView(), Gtk.Label('apps'))
		self.root_view.append_page(SystemManagerView(), Gtk.Label('system'))
		
		# press any punctuation character to switch between views
		# root_view.set_current_page(1)
		# root_view.set_current_page(2)
	
	def do_activate(self):
		if len(self.get_windows()) = 0:
			self.win = Gtk.ApplicationWindow(application=app)
			self.win.set_child(self.root_view)
			
			# when window is focused, go to app view
			
			# when window is unfocused:
			# swaymsg "[con_id=__focused__] focus" || python3 /usr/local/share/codev || swaymsg "[app_id=swapps] focus"
			subprocess.run(['swaymsg', '[con_id=__focused__] focus']) or
				subprocess.run(['python3', '/usr/local/share/codev']) or
				subprocess.run(['swaymsg', '[app_id=swapps] focus'])
		
		self.win.present()
		subprocess.run(['swaymsg', '[app_id=swapps] focus'])

MyApp().run(None)
