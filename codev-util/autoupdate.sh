metered_connection() {
	#nmcli --terse --fields GENERAL.METERED dev show | grep --quiet "yes"
	#dbus: org.freedesktop.NetworkManager Metered
}
metered_connection && exit 0

# if plugged

# inhibit suspend/shutdown when an upgrade is in progress

# if during autoupdate an error occures: echo error > /var/cache/autoupdate-status

spm update

# fwupd
# just check, if available download and show notification in status bar
