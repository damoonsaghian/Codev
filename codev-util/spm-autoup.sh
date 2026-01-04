#!/usr/bin/env sh

# a 5min delay, for when it's started on boot
sleep 300

metered="$(dbus-send --system --print-reply=literal --dest=org.freedesktop.NetworkManager \
	/org/freedesktop/NetworkManager org.freedesktop.DBus.Properties.Get \
	string:org.freedesktop.NetworkManager string:Metered | )"
[ "$metered" = NM_METERED_YES ] || [ "$metered" = NM_METERED_GUESS_YES ] && exit 1

# if plugged

spm update auto || echo error > /tmp/spm-status
