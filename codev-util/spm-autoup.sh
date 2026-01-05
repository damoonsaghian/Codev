#!/usr/bin/env sh

# a 5min delay, for when it's started on boot
sleep 300

# do not run autoupdate on metered connection
case nmcli --terse --field METERED general in
yes*) exit 11 ;;
esac

[ -e /sys/class/power_supply/BAT0 ] &&
	cat /sys/class/power_supply/BAT0/uevent | grep "POWER_SUPPLY_CAPACITY=Discharging" &>/dev/null &&
	exit 11

spm update auto || echo error > /tmp/spm-status
