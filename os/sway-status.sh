# https://github.com/enkore/i3pystatus

# show diagrams for cpu (blue), disk (red), net (yellow)

# active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
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
