# ntp sets system time based on UTC which suffers from leap seconds
# system time must be in TAI, and leap seconds must be dealt with in the timezone (the so called "right timezone")
# https://www.ucolick.org/~sla/leapsecs/right+gps.html
# https://skarnet.org/software/skalibs/flags.html#clockistai

# get the current leap seconds
# if next leap does not occure in the next 15 seconds:
chronyd -q --timeout 10 "offset $leap_seconds"
