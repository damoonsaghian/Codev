# ntp sets system time based on UTC which suffers from leap seconds
# system time must be in TAI, and leap seconds must be dealt with in the timezone (the so called "right timezone")
# https://www.ucolick.org/~sla/leapsecs/right+gps.html
# https://skarnet.org/software/skalibs/flags.html#clockistai

if [ "$1" != reboot ]; then
	# skip if uptime is less than 1 hour; because time is synced at each reboot
	[ "$(cut -f 1 -d '.' /proc/uptime)" -lt 3600 ] && exit 0
fi

# get the current leap seconds
# if next leap does not occure in the next 15 seconds:
chronyd -q --timeout 10 "offset $leap_seconds"
