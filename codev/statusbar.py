import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gio, Gdk, Gtk

# system upgrade indicator: show icon when in'progress, add ! to the icon when failed
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder
# show the restart reminder also when systemd is upgraded
# when sway is upgraded show relogin reminder

# battery: if exist, show icon
# https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/system.js
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/battery_level.py
# https://www.kernel.org/doc/html/latest/power/power_supply_class.html
# if "/sys/class/power_supply/BAT0" exists
# read "/sys/class/power_supply/BAT0/uevent"
# find "POWER_SUPPLY_CAPACITY=<value>" in contents
# POWER_SUPPLY_CAPACITY=Charging/Full/Discharging

''' cpu
, 0 to 2: white
, 2 to 50: yellow
, 50 to 90: orange
, 90 to 100: red
average over the last 30 seconds, determines the transparency
https://github.com/AstraExt/astra-monitor/tree/main/src/processor
https://gitlab.gnome.org/GNOME/gnome-usage/-/blob/main/src/cpu-monitor.vala
https://github.com/ultrabug/py3status/blob/master/py3status/modules/sysdata.py
https://github.com/fcaballerop/simple-monitor-gnome-shell-extension/blob/main/extension.js
https://github.com/eeeeeio/gnome-shell-extension-nano-system-monitor/blob/master/src/extension.js
processor-symbolic.svg
<?xml version="1.0" encoding="UTF-8"?>
<svg height="16px" viewBox="0 0 16 16" width="16px" xmlns="http://www.w3.org/2000/svg">
	<g fill="#222222">
		<path d="m 5 5 h 6 v 6 h -6 z m 0 0"/>
		<path d="m 13 5 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 13 7 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 13 9 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 0 6 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 0 8 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 0 10 h 3 v 1 h -3 z m 0 0"/>
		<path d="m 5 0 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 7 0 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 9 0 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 10 13 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 8 13 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 6 13 h 1 v 3 h -1 z m 0 0"/>
		<path d="m 5 2 c -1.644531 0 -3 1.355469 -3 3 v 6 c 0 1.644531 1.355469 3 3 3 h 6 c 1.644531 0 3 -1.355469 3 -3 v -6 c 0 -1.644531 -1.355469 -3 -3 -3 z m 0 2 h 6 c 0.570312 0 1 0.429688 1 1 v 6 c 0 0.570312 -0.429688 1 -1 1 h -6 c -0.570312 0 -1 -0.429688 -1 -1 v -6 c 0 -0.570312 0.429688 -1 1 -1 z m 0 0"/>
	</g>
</svg>
'''

''' memory
, 0 to 10: white
, 10 to 50: yellow
, 50 to 90: orange
, 90 to 100: red
average over the last 30 seconds, determines the transparency
when it reaches above 90%, it blinks
https://github.com/AstraExt/astra-monitor/tree/main/src/memory
https://gitlab.gnome.org/GNOME/gnome-usage/-/blob/main/src/memory-monitor.vala
https://github.com/ultrabug/py3status/blob/master/py3status/modules/sysdata.py
https://github.com/fcaballerop/simple-monitor-gnome-shell-extension/blob/main/extension.js
https://github.com/eeeeeio/gnome-shell-extension-nano-system-monitor/blob/master/src/extension.js
memory-symbolic.svg
<?xml version="1.0" encoding="UTF-8"?>
<svg height="16px" viewBox="0 0 16 16" width="16px" xmlns="http://www.w3.org/2000/svg">
	<g fill="#222222">
		<path d="m 3 2 c -1.660156 0 -3 1.339844 -3 3 v 4 c 0 1.660156 1.339844 3 3 3 h 10 c 1.660156 0 3 -1.339844 3 -3 v -4 c 0 -1.660156 -1.339844 -3 -3 -3 z m 0 2 h 10 c 0.554688 0 1 0.445312 1 1 v 4 c 0 0.554688 -0.445312 1 -1 1 h -10 c -0.554688 0 -1 -0.445312 -1 -1 v -4 c 0 -0.554688 0.445312 -1 1 -1 z m 0 0"/>
		<path d="m 2 10 h 12 v 4 h -12 z m 0 0"/>
		<g fill-opacity="0.5">
			<path d="m 4 5 h 2 v 4 h -2 z m 0 0"/>
			<path d="m 7 5 h 2 v 4 h -2 z m 0 0"/>
			<path d="m 10 5 h 2 v 4 h -2 z m 0 0"/>
		</g>
	</g>
</svg>
'''

import re

with open('/proc/meminfo') as mem_info_file:
	mem_info = mem_info_file.read()
	mem_total = re.compile(r"MemTotal:\s+(\d+) kB").match(mem_info)
	mem_total = int(mem_total)
	mem_available = re.compile(r"MemAvailable:\s+(\d+) kB").match(mem_info)
	mem_available = int(mem_available)
	mem_usage = (mem_total - mem_available) / mem_total

# disk
# writing: red icon
# reading: yellow icon
# reading and writing: orange icon
# if there is no read/write now, but there was one in the last 15 seconds, dim the corresponding color
# https://github.com/AstraExt/astra-monitor/tree/main/src/storage
# https://unix.stackexchange.com/questions/55212/how-can-i-monitor-disk-io
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/diskdata.py

# icon's color indicates average speed (download+upload) in the last 30 seconds:
# , 0 to 10 kB/s: white icon
# , 10 kbs to 100 kB/s: yellow icon
# , 100 kbs to 1 MB/s: green icon
# , greater than 1 MB/s: blue icon
# show upload speed, and total upload since boot, in the top index
# show download speed, and total download since boot, in the bottom index

''' internet
icon's color indicates average speed (download+upload) in the last 30 seconds:
, 0 to 10 kB/s: white icon
, 10 kbs to 100 kB/s: yellow icon
, 100 kbs to 1 MB/s: green icon
, greater than 1 MB/s: blue icon
show upload speed, and total upload since boot, in the top index
show download speed, and total download since boot, in the bottom index
https://github.com/AstraExt/astra-monitor/tree/main/src/network
https://github.com/ultrabug/py3status/blob/master/py3status/modules/netdata.py
https://github.com/ultrabug/py3status/blob/master/py3status/modules/net_rate.py
https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/network.js
https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/rfkill.js
https://github.com/AlynxZhou/gnome-shell-extension-net-speed/blob/master/extension.js
https://github.com/rishuinfinity/InternetSpeedMonitor/blob/master/src/extension.js
https://github.com/eeeeeio/gnome-shell-extension-nano-system-monitor/blob/master/src/extension.js
active_net_device="$(networkctl list | grep routable | { read -r _ net_dev _; echo $net_dev; })"
[ -n "$active_net_device" ] && {
	read -r internet_rx < "/sys/class/net/$active_net_device/statistics/rx_bytes"
	read -r internet_tx < "/sys/class/net/$active_net_device/statistics/tx_bytes"
	internet_total=$(( (internet_rx + internet_tx)/100000 ))
	
	internet_speed=$(( (internet_total - last_internet_total) / interval ))
	last_internet_total=$internet_total
	
	# if there was network activity in the last 60 seconds, set color to green
	internet_speed_average=$(( (internet_speed + internet_speed_average*lmaf) / (lmaf+1) ))
	[ "$internet_speed_average" = 0 ] || internet_icon_foreground_color="foreground=\"green\""
	
	# each 20 seconds check for online status
	internet_online=1
	[ "$internet_online" = 0 ] && internet_icon_foreground_color='foreground="red"'
	
	internet_speed="$(( internet_speed/10 )).$(( internet_speed%10 ))"
	internet_total="$(( internet_total/10000 )).$(( (internet_total/1000)%10 ))"
	internet="$internet_total<span $internet_icon_foreground_color>  </span>$internet_speed"
}
'''
	
# wifi: if exists, show icon
# 0 to 20: none icon
# 20 to 50: weak icon
# 50 to 80: ok icon
# 80 to 90: good icon
# 90 to 100: excellent icon
# wifi signal strength:
# iwctl station wlan0 show -> RSSI, AverageRSSI
# https://www.reddit.com/r/archlinux/comments/gbx3sf/iwd_users_how_do_i_get_connected_channel_strength/
# https://wireless.wiki.kernel.org/en/users/documentation/iw
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/wifi.py

# cell
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/wwan.py
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/wwan_status.py
	
# bluetooth
# https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/bluetooth.js
# https://github.com/ultrabug/py3status/blob/master/py3status/modules/bluetooth.py

# audio (pipewire output):
# if audio out device is not dummy, show icon
# 0: muted icon
# 1 to 80: low icon
# 80 to 99: medium icon
# 100: high icon
# https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/volume.js

# mic (pipewire input)
# https://github.com/xenomachina/i3pamicstatus

# cam
# visible only when it's active
# https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/status/camera.js

# screen recorder indicator: watch for $HOME/.cache/screen-capture contains the pid of screenrec process

# time: %Y-%m-%d %a %p %I:%M
# https://stackoverflow.com/questions/13527451/how-can-i-catch-a-system-suspend-event-in-python
# connection.add_signal_receiver(
# 	'org.freedesktop.UPower', 'org.freedesktop.UPower', 'Resuming',
# 	'/org/freedesktop/UPower', None, Gio.DBusSignalFlags.NONE,
# 	function() print "System just resumed from hibernate or suspend" end
# )

# click on empty space, or status area:
# swaymsg '[app_id=swapps] focus' || python3 /usr/local/share/swapps.py
