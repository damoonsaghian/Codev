apk_new networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq tzdata chrony
rc_new networkmanager

# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-timezone.in
printf '#!/apps/env sh
set -e
if [ "$1" = set ]; then
	tz="$2"
	[ -f /usr/share/zoneinfo/"$tz" ] &&
		ln -s /usr/share/zoneinfo/right/"$tz" /var/lib/netman/tz
elif [ "$1" = continents ]; then
	ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5
elif [ "$1" = cities ]; then
	ls -1 /usr/share/zoneinfo/"$2"/* | cut -d / -f6
elif [ "$1" = check ]; then
	# get timezone from location
	# https://www.freedesktop.org/software/geoclue/docs/gdbus-org.freedesktop.GeoClue2.Location.html
	# https://github.com/evansiroky/timezone-boundary-builder (releases -> timezone-with-oceans-now.geojson.zip)
	# https://github.com/BertoldVdb/ZoneDetect
	# tz set "$continent/$city"
else
	echo "usage:"
	echo "	tz set <continent/city>"
	echo "	tz continents"
	echo "	tz cities <continent>"
	echo "	tz check"
fi
' > /usr/local/bin/tz
chmod +x /usr/local/bin/tz
# doas rule

echo '#!/bin/sh
tz check
' > /etc/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /etc/NetworkManager/dispatcher.d/09-dispatch-script
# https://wiki.archlinux.org/title/NetworkManager#Network_services_with_NetworkManager_dispatcher

# wpa_supplicant or iwd (without dhcp)

# https://gitlab.freedesktop.org/mobile-broadband/ModemManager

# https://gitlab.freedesktop.org/geoclue/geoclue
# libgeoclue=false introspection=false gtk-doc=false
# wifi-source=false wifi-source=false 3g-source=false ip-source=false 
# avahi-glib: build and statically link

# https://gitlab.alpinelinux.org/alpine/alpine-conf/-/blob/master/setup-ntp.in
# ntp sets system time based on UTC which suffers from leap seconds
# "chrony -Q" prints the offset; add it to leap seconds, and adjust the system time using "adjtimex" command
# for this to work properly, system timezone must be set from "right" timezones in tzdata
# https://www.ucolick.org/~sla/leapsecs/right+gps.html
# https://skarnet.org/software/skalibs/flags.html#clockistai
# when chrony can't adjust time, try to set it using the time reported by modemmanager
printf '\nFAST_STARTUP=yes\n' >> "$new_root"/etc/conf.d/chronyd
rc_new chrony
