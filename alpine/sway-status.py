from gi.repository import Gio, GLib

connection = Gio.DBus.system

# https://bootlin.com/pub/conferences/2016/meetup/dbus/josserand-dbus-meetup.pdf#page=26

# https://github.com/Templarian/MaterialDesign-Font

# https://py3status.readthedocs.io/en/latest/user-guide/modules/#netdata

# https://manpages.debian.org/unstable/sway/swaybar-protocol.7.en.html
# https://github.com/i3/i3status/tree/main/contrib

# each minute calculate network timezone (using Ofono and geoip)
# if it's not equal to the system timezone, add it as an additional date'time to the status bar
# unfortunately it seems that Ofono does not have any dbus api to get network timezone
# https://git.kernel.org/pub/scm/network/ofono/ofono.git/tree/doc
# https://git.kernel.org/pub/scm/network/ofono/ofono.git/tree/src/nettime.c
# https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/gdbus-org.freedesktop.ModemManager1.Modem.Time.html
# https://lazka.github.io/pgi-docs/ModemManager-1.0/classes/NetworkTimezone.html
system_tz="$(readlink /etc/localtime)"
system_tz="$(dirname $system_tz)/$(basename $system_tz)"
ofono_tz=
geoip_tz="$(wget -q -O- http://ip-api.com/line/?fields=timezone)"
net_tz=
if [ "$net_tz" != "$system_tz" ]; then
fi

def datetime():
	# "%Y-%m-%d  %a  %p  %I:%M"
	# calculate full minute
	sec_til_full_minute = 60 -
	# monitor for resume and timezone via dbus
	
	# https://stackoverflow.com/questions/13527451/how-can-i-catch-a-system-suspend-event-in-python
	def on_system_resume():
		print "System just resumed from hibernate or suspend"
	connection.add_signal_receiver(
		'org.freedesktop.UPower', 'org.freedesktop.UPower', 'Resuming',
		'/org/freedesktop/UPower', None, Gio.DBusSignalFlags.NONE,
		on_system_resume)
	
	# https://www.freedesktop.org/software/systemd/man/org.freedesktop.timedate1.html
	# whenever the Timezone and LocalRTC settings are changed via the daemon,
	# PropertyChanged signals are sent out to which clients can subscribe
	
	# when networks changes, check timezone, and if it's different from the system's timezone,
	# show an additional date'time for that timezone, plus the timezone
	# https://gitlab.com/craftyguy/networkd-dispatcher
	# https://github.com/a-sk/connman-dispatcher
	# tz_system="$(timedatectl show --value --property Timezone)"
	# tz_geoip="$(wget2 -q -O- http://ip-api.com/line/?fields=timezone)"
	# continent="$(printf "$tz" | cut -d / -f1)"
	# city="$(printf "$tz" | cut -d / -f2)"
	# if [ "$tz_geoip" != "$tz_system" ]; then
	#   #show an additional date'time for that timezone, plus the timezone
	# fi

# battery
with open("/sys/class/power_supply/BAT0/energy_full") as f:
    full = float(f.read())
with open("/sys/class/power_supply/BAT0/energy_now") as f:
    now = float(f.read())
battery_percentage = str(int(now / full * 100))

# cpu (/proc/stat) ram (/proc/meminfo) disk net (sum since login)

# active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
#
# net speed:
# device-path/statistics/tx_bytes
# device-path/statistics/rx_bytes
# https://github.com/i3/i3status/blob/master/contrib/net-speed.sh
#
# total internet (non'local) traffic
#
# wifi signal strength
# iwctl station wlan0 show -> RSSI, AverageRSSI
# https://www.reddit.com/r/archlinux/comments/gbx3sf/iwd_users_how_do_i_get_connected_channel_strength/
# https://wireless.wiki.kernel.org/en/users/documentation/iw
#
# https://github.com/greshake/i3status-rust/blob/master/src/blocks/net.rs
# BitRates: https://man.archlinux.org/man/core/systemd/org.freedesktop.network1.5.en
# https://github.com/Alexays/Waybar/wiki/Module:-Network

# bluetooth

# font-awesome

# https://github.com/enkore/i3pystatus
# https://github.com/greshake/i3status-rust
# libgtop
# https://gitlab.gnome.org/GNOME/gnome-usage

# package manager indicator: in'progress, system upgraded
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder

# backup indicator: in'progress, completed

loop = gobject.MainLoop()
loop.run()
