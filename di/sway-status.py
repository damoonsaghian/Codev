import dbus
import gobject
from dbus.mainloop.glib import DBusGMainLoop

# "%Y-%m-%d  %a  %p  %I:%M"
# calculate full minute
sec_til_full_minute = 60 -
# monitor for resume and timezone via dbus

def handle_resume_callback():
  print "System just resumed from hibernate or suspend"

DBusGMainLoop(set_as_default=True) # integrate into main loob
bus = dbus.SystemBus()             # connect to dbus system wide
bus.add_signal_receiver(           # defince the signal to listen to
  handle_resume_callback,            # name of callback function
  'Resuming',                        # singal name
  'org.freedesktop.UPower',          # interface
  'org.freedesktop.UPower'           # bus name
)

# https://www.freedesktop.org/software/systemd/man/org.freedesktop.timedate1.html
# whenever the Timezone and LocalRTC settings are changed via the daemon,
#   PropertyChanged signals are sent out to which clients can subscribe

# battery
with open("/sys/class/power_supply/BAT0/energy_full") as f:
    full = float(f.read())
with open("/sys/class/power_supply/BAT0/energy_now") as f:
    now = float(f.read())
battery_percentage = str(int(now / full * 100))

# cpu (/proc/stat) ram (/proc/meminfo) disk net (sum since login)

# active network device:
#   ip route show default
# net speed:
#   device-path/statistics/tx_bytes
#   device-path/statistics/rx_bytes
#   https://github.com/i3/i3status/blob/master/contrib/net-speed.sh
# total internet consumption
# wifi signal strength
#   iwctl station wlan0 show -> RSSI, AverageRSSI
#   https://www.reddit.com/r/archlinux/comments/gbx3sf/iwd_users_how_do_i_get_connected_channel_strength/
#   https://wireless.wiki.kernel.org/en/users/documentation/iw
# https://github.com/greshake/i3status-rust/blob/master/src/blocks/net.rs
# https://man.archlinux.org/man/core/systemd/org.freedesktop.network1.5.en
#   BitRates
# https://github.com/Alexays/Waybar/wiki/Module:-Network

# bluetooth

# font-awesome

# https://github.com/enkore/i3pystatus
# libgtop
# https://gitlab.gnome.org/GNOME/gnome-usage


# update indicator: in'progress, completed
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder

# backup indicator: in'progress, completed

loop = gobject.MainLoop()
loop.run()
