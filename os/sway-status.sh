i3status -c /usr/local/share/i3status.conf | while true; do
	IFS="|" read cpu mem bat audio time
	cpu="$cpu  "
	mem="$mem  "
	# bat_status: CHR, BAT, UNK, FULL (charging, discharging, unknown, full)
	bat="$bat  "
	audio_out_dev="$(echo $audio | cut -f 1 -d " ")"
	audio_out="$(echo $audio | cut -f 2 -d " ")"
	# if audio_out_dev is a dummy output, hide it
	mic=
	cam=
	echo "$cpu$mem$disk$net$bat$audio$mic$cam$time" || exit 1
done

# battery: 󰁺󰁻󰁼󰁽󰁾󰁿󰂀󰂁󰂂󰁹
# battery charging: 󰢜󰂆󰂇󰂈󰢝󰂉󰢞󰂊󰂋󰂅

# show diagrams for cpu (blue), ram (green), disk (red), net (yellow)
# each diagram is made of two characters which can be any of these: ▁▂▃▄▅▆▇█
# for each block there are two characters
# the first one shows the average value (the past 60 seconds)
# the other one shows the current value
# the backgrounds have the light version of the mentioned colors
# cpu: /proc/stat
# ram: /proc/meminfo
# net: also show the speed in numbers, as well as the sum since login

# average: (new'value/30 + last'value)/2

# net speed:
# device-path/statistics/tx_bytes
# device-path/statistics/rx_bytes
# https://github.com/i3/i3status/blob/main/contrib/net-speed.sh
#
# BitRates: https://man.archlinux.org/man/core/systemd/org.freedesktop.network1.5.en
# https://github.com/greshake/i3status-rust/blob/master/src/blocks/net.rs
# https://github.com/Alexays/Waybar/wiki/Module:-Network
#
# total internet (non'local) traffic since login
#
# wifi signal strength
# iwctl station wlan0 show -> RSSI, AverageRSSI
# https://www.reddit.com/r/archlinux/comments/gbx3sf/iwd_users_how_do_i_get_connected_channel_strength/
# https://wireless.wiki.kernel.org/en/users/documentation/iw

# bluetooth

# package manager indicator: in'progress, system upgraded
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder

# backup indicator: in'progress, completed

# https://docs.gtk.org/Pango/pango_markup.html
