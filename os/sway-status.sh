i3status -c /usr/local/share/i3status.conf | while :
do
	read i3status
	
	# derive individual modules from $i3status
	
	sway_status=
	
	echo "$sway_status" || exit 1
done

# https://github.com/Templarian/MaterialDesign-Font
# font-awesome

# https://github.com/enkore/i3pystatus
# https://github.com/greshake/i3status-rust
# libgtop
# https://gitlab.gnome.org/GNOME/gnome-usage

# https://py3status.readthedocs.io/en/latest/user-guide/modules/#netdata

# https://manpages.debian.org/unstable/sway/swaybar-protocol.7.en.html
# https://github.com/i3/i3status/tree/main/contrib

# show diagrams for cpu (blue), ram (green), disk (red), net (yellow)
# each diagram is made of two characters which can be any of these: ▁▂▃▄▅▆▇█
# for each block there are two characters
# the first one shows the average value (the past 60 seconds)
# the other one shows the current value
# the backgrounds have the light version of the mentioned colors
# cpu: /proc/stat
# ram: /proc/meminfo
# net: also show the speed in numbers, as well as the sum since login

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

# package manager indicator: in'progress, system upgraded
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder

# backup indicator: in'progress, completed
