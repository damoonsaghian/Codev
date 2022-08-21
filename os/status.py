# https://github.com/i3/i3status/blob/master/contrib/wrapper.py

# make_graph in: https://github.com/enkore/i3pystatus/blob/current/i3pystatus/core/util.py

# font-awesome

# %F %a % p %I:%M
# if "/usr/local/share/tz-geoip" exists, show additional time indictor for that timezone
# date +%z
# wget -q -O- http://ip-api.com/line/?fields=timezone

# battery
# cpu ram disk net (sum since login)

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

# libgtop
# https://gitlab.gnome.org/GNOME/gnome-usage
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/custom_statusbar
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/cirno/custom_statusbar
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/cirno/batpct

# update indicator: in'progress, completed
# https://github.com/enkore/i3pystatus/wiki/Restart-reminder

# backup indicator: in'progress, completed
