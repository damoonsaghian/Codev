# i3pystatus
# https://i3pystatus.readthedocs.io/en/latest/
# https://computingforgeeks.com/configure-i3pystatus-on-linux/
# https://github.com/enkore/i3pystatus/wiki
# font-awesome
# %F %a % p %I:%M

# cpu ram disk net (sum since login)

# active network device:
#   ip route show default
# net speed:
#   device-path/statistics/tx_bytes
#   device-path/statistics/rx_bytes
# total internet consumption
# wifi signal strength
#   iwctl station wlan0 show -> RSSI, AverageRSSI
#   https://www.reddit.com/r/archlinux/comments/gbx3sf/iwd_users_how_do_i_get_connected_channel_strength/
#   https://wireless.wiki.kernel.org/en/users/documentation/iw
# https://github.com/greshake/i3status-rust/blob/master/src/blocks/net.rs
# https://man.archlinux.org/man/core/systemd/org.freedesktop.network1.5.en
#   BitRates
# https://github.com/Alexays/Waybar/wiki/Module:-Network

# cpu ram disk net (sum since login)
# libgtop
# https://gitlab.gnome.org/GNOME/gnome-usage
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/custom_statusbar
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/cirno/custom_statusbar
# https://git.sr.ht/~sircmpwn/dotfiles/tree/master/item/bin/cirno/batpct

# periodically check for location and if it's not the same as the set timezone, add an additional date indicator,
#   and if there is no file named "~/.cache/tz create it
# if the file exists and it's older than a week then change the timezone,
#   and delete the file and the additional date indicator

# backup indicator: in'progress, completed
# update indicator checks if there is an updated subvolume
