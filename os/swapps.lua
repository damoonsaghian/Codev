local lgi = require'lgi'
-- work around for Gtk4:
if require'lgi.version' <= '0.9.2' then
	local lgi_namespace = require'lgi.namespace'
	local lgi_namespace_require
	lgi_namespace_require = function(name, version)
		local core = require'lgi.core'
		local ns_info = assert(core.gi.require(name, version))
		local ns = rawget(core.repo, name)
		if not ns then
			ns = setmetatable(
				{ _name = name, _version = ns_info.version, _dependencies = ns_info.dependencies },
				lgi_namespace.mt
			)
			core.repo[name] = ns
			for name, version in pairs(ns._dependencies or {}) do
				lgi_namespace_require(name, version)
			end
			if ns._name ~= "Gtk" and ns._name ~= "Gdk" then
				local override_name = 'lgi.override.' .. ns._name
				local ok, msg = pcall(require, override_name)
				if not ok then
					if not msg:find("module '" .. override_name .. "' not found:", 1, true) then
						package.loaded[override_name] = nil
						require(override_name)
					end
				end
				if ok and type(msg) == "string" then error(msg) end
			end
		end
		return ns
	end
	lgi.require = lgi_namespace_require
	lgi.Gtk.disable_setlocale()
	lgi.Gtk.init()
end

local gio = lgi.require'Gio'
local gdk = lgi.require('Gdk', '4.0')
local gtk = lgi.require('Gtk', '4.0')
local vte = lgi.require('Vte', '3.91')

local app = gtk.Application{ application_id = 'swapps' }

app.on_startup = function(app)
	local root_view = gtk.Notebook()
	root_view:append_page(create_app_launcher_view(), gtk.Label"apps")
	root_view:append_page(create_session_manager_view(), gtk.Label"session")
	
	local win = gtk.ApplicationWindow{ application = app }
	win:set_child(root_view)
end

app.on_activate = function(app)
	app:get_windows()[1].present()
end

app:run()

Gtk.Box create_apps_launcher() {
	var app_launcher_box = Gtk.Box(Gtk.Orientation.VERTICAL, 5)
	app_launcher_box.margin_top = 5;
	app_launcher_box.margin_bottom = 5;
	app_launcher_box.margin_start = 5;
	app_launcher_box.margin_end = 5;
	
	var app_search_entry = Gtk.SearchEntry();
	app_launcher_box.append(app_search_entry);
	
	app_search_entry.search_changed.connect(() => {
		// find and select the first item whose name matches: string:gsub(search_entry.text, " ", ".* ")
	});
	
	app_search_entry.activate.connect(() => {
		var app_item = this.apps_list.get_selected();
		os.execute("swaymsg workspace " .. string.format('%q', app_item:get_name()));
		var error_code = os.execute("swaymsg '[con_id=__focused__] focus'");
		if (error_code != 0) {
			os.execute('swaymsg exec ' .. string.format('%q', app_item:get_commandline()));
		}
		os.execute("swaymsg move scratchpad");
		// swaymsg "[con_id=codev] focus" || python3 /usr/local/share/codev
		// swaymsg "[app_id=codev] move workspace $app; workspace $app"; app.exec
	});
	
	// clear search entry, when refocused
	
	var apps_list = Gio.ListStore(Gio.AppInfo);
	
	CompareDataFunc<Gio.AppInfo> compare_apps = (app1, app2) => {
		app1_name = app1.get_name()
		app2_name = app2.get_name()
		if app2_name > app1_name:
			return -1
		elif app1_name > app2_name:
			return 1
		else:
			return 0
	}
	
	delegate void AppsListUpdateHandler(AppInfoMonitor monitor);
	AppsListUpdateHandler update_apps_list = (_) => {
		string app_name;
		apps_list.remove_all();
		for _, app in ipairs(gio.AppInfo.get_all()) {
			app_name = app.get_name();
			if (app.should_show()) {
				apps_list.insert_sorted(app, compare_apps);
			}
		}
	}
	
	update_apps_list();
	Gio.AppInfoMonitor.get().changed.connect(update_apps_list);
		
	var apps_flowbox = Gtk.FlowBox();
	apps_flowbox.orientation = Gtk.Orientation.HORIZONTAL;
	apps_flowbox.column_spacing = 5;
	apps_flowbox.row_spacing = 5;
	apps_flowbox.margin_top = 5;
	apps_flowbox.margin_bottom = 5;
	apps_flowbox.margin_start = 5;
	apps_flowbox.margin_end = 5;
	apps_flowbox.selection_mode = Gtk.SelectionMode.NONE;
	apps_flowbox.focusable = false;
	apps_flowbox.bind_model(apps_list, (app_item) => {
		var label = Gtk.Label();
		label.label = app_item.get_name();
		label.justify = Gtk.Justification.CENTER;
		label.width_chars=20;
		
		var icon = Gtk.Image.new_from_gicon(app_item.get_icon());
				
		var event_controller = Gtk.EventControllerKey();
		event_controller.key_pressed.connect((_, keyval) => {
			if (keyval == Gdk.BUTTON_PRIMARY) {
				self.raise_or_run_app(app_item);
			}
		});
		
		var widget = gtk.Box(gtk.Orientation.VERTICAL, 5);
		widget.append(label);
		widget.append(icon);
		widget.add_controller(event_controller);
		return widget;
	});
		
	var scrolled_window = Gtk.ScrolledWindow();
	scrolled_window.child = apps_flowbox;
	apps_launcher_box.append(scrolled_window);
	
	return apps_launcher_box;
}

Gtk.Stack create_system_manager() {
	var system_manager = Gtk.Stack();
	system_manager.orientation = Gtk.Orientation.VERTICAL;
	
	// create a SysManPage, and connect to its "clear", "close", and "new_menu" signal
	// session manager, connections, timezone, passwords, packages
	
	// clear signal: remove all pages except the first one, clear search entry
	
	return system_manager;
}

class SysManPage : Gtk.Box {
	signal clear();
	signal close();
	signal new_menu();
	
	SysManPage() {
		var search_entry = Gtk.SearchEntry();
		search_entry.search_changed.connect(() => {});
		search_entry.activate.connect(() => {});
		// when refocused: emit clear signal
		
		this.append(search_entry);
		
		// space at the beginning, or two spaces: emit clear signal
		// refocused: emit clear signal
		
		// when an item is activated:
		// if it has a command, run it and emit a close signal
		// otherwise emit a new_menu signal, containing the menu
	}
}

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

/*
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
*/

void main () {
	var my_app = Gtk.Application("swapps", Gtk.ApplicationFlags.DEFAULT_FLAGS)
	
	var root_view = Gtk.Notebook();
	
	my_app.startup.connect(() => {
		root_view.append_page(create_apps_launcher(), Gtk.Label('apps'));
		root_view.append_page(create_system_manager(), Gtk.Label('system'));
		
		// press any punctuation character to switch between views
		// root_view.set_current_page(1)
		// root_view.set_current_page(2)
		
		var window = Gtk.ApplicationWindow(app);
		window.set_child(this.root_view);
		
		// when window is focused, go to app view
		
		// when window is unfocused:
		// swaymsg "[con_id=__focused__] focus" || codev || swaymsg "[app_id=swapps] focus"
	});
	
	my_app.activate.connect((app) => {
		var windows = this.get_windows();
		foreach (Gtk.Window win in windows) {
			win.present();
		}
		subprocess.run(['swaymsg', '[app_id=swapps] focus']);
	});
	
	my_app.run()
}
