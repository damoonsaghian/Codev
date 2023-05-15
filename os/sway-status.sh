graph() {
	percentage="$(echo $1 | cut -d % -f 1 | cut -d . -f 1)"
	percentage_average="$(echo $2 | cut -d % -f 1 | cut -d . -f 1)"
	
	if [ "$percentage" = 0 ]; then
		graph=" "
	elif [ "$percentage" = 100 ]; then
		graph="█"
	else
		index="$((percentage/10))"
		graph="$(echo "▁ ▂ ▂ ▃ ▄ ▅ ▅ ▆ ▇" | cut -d " " -f "$index")"
	fi
	
	[ "$percentage" -gt 95 ] && foreground_color='foreground="red"'
	
	if [ "$percentage_average" -gt 90 ]; then
		echo "<span $foreground_color background=\"#ffcccc\">$graph</span>"
	elif [ "$percentage_average" -gt 50 ]; then
		echo "<span $foreground_color background=\"#ccffcc\">$graph</span>"
	elif [ "$percentage_average" -gt 5 ]; then
		echo "<span $foreground_color background=\"#99ccff\">$graph</span>"
	else
		echo "<span $foreground_color background=\"#4d4d4d\">$graph</span>"
	fi
}

i3status -c /usr/local/share/i3status.conf | while true; do
	IFS=" | " read cpu_usage mem_usage bat wifi audio time
	
	cpu="$(graph "$cpu_usage" "$cpu_usage_average")"
	[ -z "$cpu_usage_average" ] && cpu_usage_average="$cpu_usage"
	cpu_usage_average="$(((cpu_usage + cpu_usage_average*30)/31))"
	
	mem="$(graph "$mem_usage" "$mem_usage_average")"
	[ -z "$mem_usage_average" ] && mem_usage_average="$mem_usage"
	mem_usage_average="$(((mem_usage + mem_usage_average*30)/31))"

	disk=""
	# if writing to disk, disk_w=30
	# if reading from disk, disk_r=30
	# https://packages.debian.org/sid/sysstat
	# https://unix.stackexchange.com/questions/55212/how-can-i-monitor-disk-io
	if [ -n "$disk_w" ]; then
		if [ "$disk_w" -eq 30 ]; then
			disk="<span foreground=\"red\"></span>"
		else
			disk="<span foreground=\"#ffcccc\"></span>"
		fi
		disk_w="$((disk_w - 2))"
		[ "$disk_w" = 0 ] && disk_w=""
	fi
	if [ -n "$disk_r" ]; then
		if [ "$disk_r" -eq 30 ]; then
			disk="<span foreground=\"#0099ff\"></span>"
			[ "$disk_w" -eq 28 ] && disk="<span foreground=\"#ff00ff\"></span>"
		else
			disk="<span foreground=\"#ccffff\"></span>"
			[ -n "$disk_w" ] && disk="<span foreground=\"#ffccff\"></span>"
		fi
		disk_r="$((disk_r - 2))"
		[ "$disk_r" = 0 ] && disk_r=""
	fi
	
	# backup (sync) indicator: in'progress, completed
	# "  "
	backup=
	
	# system upgrade indicator: in'progress (red), system upgraded (green)
	# https://github.com/enkore/i3pystatus/wiki/Restart-reminder
	# "  "
	pm=
	
	if [ "$bat" = null ]; then
		bat=""
	else
		bat_status="$(echo $bat | cut -d ": " -f 1)"
		bat_percentage="$(echo "$bat" | cut -d ": " -f 2)"
		bat="$(echo "          " | cut -d " " -f $((bat_percentage/10)))"
		bat="  $bat"
		[ "$bat_percentage" -lt 10 ] && bat="<span foreground=\"yellow\">$bat</span>"
		[ "$bat_percentage" -lt 5 ] && bat="<span foreground=\"red\">$bat</span>"
		[ "$bat_status" = CHR ] && bat="<span foreground=\"green\">$bat</span>"
	fi
	
	# "$gnunet_total$gnunet_speed  "
	gnunet=
	
	# show the download/upload speed, plus total rx/tx since boot
	active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
	[ -n "$active_net_device" ] && {
		read internet_rx < "/sys/class/net/$active_net_device/statistics/rx_bytes"
		read internet_tx < "/sys/class/net/$active_net_device/statistics/tx_bytes"
		internet_total=$((internet_rx/8000 + internet_tx/8000))
		[ "$internet_total" -gt 999 ] && internet_total=$((internet_total/1000))
		#internet_speed="[]"
		
		# if not online, set the color of the globe icon to red
		# if there was network activity in the last 30 seconds, set color to green
		
		internet="$internet_total$internet_speed"
		
		[ -z "$internet_percent_average" ] && internet_percent_average="$internet_percent"
		internet_percent_average="$(((internet_percent + internet_percent_average*30)/31))"
	}
	
	if [ "$wifi" = null ]; then
		wifi=""
	else
		wifi_percentage="$wifi"
		wifi="  "
		[ "$wifi_percentage" -lt 75 ] && wifi="<span foreground=\"#ffffcc\">$wifi</span>"
		[ "$wifi_percentage" -lt 50 ] && wifi="<span foreground=\"red\">$wifi</span>"
		[ "$wifi_percentage" -lt 25 ] && wifi="<span foreground=\"#ff00ff\">$wifi</span>"
	fi
	
	# cell: "  "
	
	# bluetooth: "  "
	bluetooth=
	
	audio_out_dev="$(echo $audio | cut -d ": " -f 1)"
	if [ "$audio_out_dev" = "Dummy Output" ]; then
		audio=""
	else
		audio_out_vol="$(echo $audio | cut -d ": " -f 2 | cut -d % -f 1)"
		if [ "$audio_out_vol" -eq 100 ]; then
			audio="  "
		elif [ "$audio_out_vol" -eq 0 ]; then
			audio="  "
		else
			audio="<span foreground=\"#ffffcc\">  </span>"
			[ "$audio_out_vol" -lt 50 ] && audio="<span foreground=\"#ffffcc\">  </span>"
			[ "$audio_out_vol" -lt 20 ] && audio="<span foreground=\"#ffffcc\">  </span>"
			[ "$audio_out_vol" -lt 10 ] && audio="<span foreground=\"red\">  </span>"
		fi
	fi
	
	# mic: "  "
	# visible only when it's active; green if volume is full, yellow and red if volume is low
	# mic muted: "  "
	# https://github.com/xenomachina/i3pamicstatus
	#audio_In_dev=
	#[ "$audio_In_dev" = "Dummy Input" ] && mic=""
	
	# cam: "<span foreground=\"green\">  </span>"
	# visible only when it's active
	cam=
	
	# screen recording: "<span foreground=\"red\">⬤  </span>"
	scr=
	
	echo "  $cpu$mem  $disk$backup$pm$bat  $gnunet$internet  $wifi$cell$bluetooth$audio$mic$cam$scr$time" || exit 1
done
