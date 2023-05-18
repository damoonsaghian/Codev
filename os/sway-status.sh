graph() {
	local graph= foreground_color=
	local percentage="$(echo $1 | cut -d % -f 1 | cut -d . -f 1)"
	local percentage_average="$(echo $2 | cut -d % -f 1 | cut -d . -f 1)"
	
	if [ "$percentage" = 0 ]; then
		graph=" "
	elif [ "$percentage" = 100 ]; then
		graph="█"
	else
		graph="$(echo "▁ ▂ ▂ ▃ ▄ ▅ ▅ ▆ ▇" | cut -d " " -f $(( percentage/10 )))"
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

last_time=0
cpu_usage_average=0
mem_usage_average=0
last_internet_total=0
last_internet_total=0
internet_speed_average=0

i3status -c /usr/local/share/i3status.conf | while true; do
	IFS=" | " read cpu_usage mem_usage bat_i3s wifi_i3s audio_i3s scrrec time_i3s
	
	time=$(date +%s)
	interval=$(( $time - $last_time ))
	[ $interval -gt 0 ] || {
		echo "  $cpu$mem  $disk$backup$pm$bat  $gnunet$internet  $wifi$cell$blt$audio$mic$cam$scr$time_i3s"
		continue
	}
	last_time=$time
	# last'minute average factor
	lmaf=$(( 60 / $interval ))
	
	cpu="$(graph "$cpu_usage" "$cpu_usage_average")"
	cpu_usage_average=$(( (cpu_usage + cpu_usage_average*lmaf) / (lmaf+1) ))
	
	mem="$(graph "$mem_usage" "$mem_usage_average")"
	mem_usage_average=$(( (mem_usage + mem_usage_average*lmaf) / (lmaf+1) ))

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
		disk_w=$(( disk_w - interval ))
		[ "$disk_w" -lte 1 ] && disk_w=""
	fi
	if [ -n "$disk_r" ]; then
		if [ "$disk_r" -eq 30 ]; then
			disk="<span foreground=\"#0099ff\"></span>"
			[ "$disk_w" -eq 28 ] && disk="<span foreground=\"#ff00ff\"></span>"
		else
			disk="<span foreground=\"#ccffff\"></span>"
			[ -n "$disk_w" ] && disk="<span foreground=\"#ffccff\"></span>"
		fi
		disk_r=$(( disk_r - interval ))
		[ "$disk_r" -lte 1 ] && disk_r=""
	fi
	
	# backup (sync) indicator: in'progress, completed
	# "  "
	backup=
	
	# system upgrade indicator: in'progress (red), system upgraded (green)
	# https://github.com/enkore/i3pystatus/wiki/Restart-reminder
	# "  "
	pm=
	
	if [ "$bat_i3s" = null ]; then
		bat=""
	else
		bat_status="$(echo $bat_i3s | cut -d ": " -f 1)"
		bat_percentage="$(echo "$bat_i3s" | cut -d ": " -f 2)"
		bat="$(echo "          " | cut -d " " -f $(( bat_percentage/10 )))"
		bat="  $bat"
		[ "$bat_percentage" -lt 10 ] && bat="<span foreground=\"yellow\">$bat</span>"
		[ "$bat_percentage" -lt 5 ] && bat="<span foreground=\"red\">$bat</span>"
		[ "$bat_status" = CHR ] && bat="<span foreground=\"green\">$bat</span>"
	fi
	
	# "$gnunet_total[$gnunet_speed]  "
	gnunet=
	
	# show the download/upload speed, plus total rx/tx since boot
	active_net_device="$(ip route show default | head -1 | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')"
	[ -n "$active_net_device" ] && {
		read internet_rx < "/sys/class/net/$active_net_device/statistics/rx_bytes"
		read internet_tx < "/sys/class/net/$active_net_device/statistics/tx_bytes"
		internet_total=$(( (internet_rx + internet_tx)/1000000 ))
		
		internet_speed=$(( (internet_total - last_internet_total) / interval ))
		last_internet_total=$internet_total
		
		# if there was network activity in the last 60 seconds, set color to green
		internet_speed_average=$(( (internet_speed + internet_speed_average*lmaf) / (lmaf+1) ))
		[ "$internet_speed_average" = 0 ] || internet_icon_foreground_color="foreground=\"green\""
		
		# each 20 seconds check for online status
		internet_online=1
		[ "$internet_online" = 0 ] && internet_icon_foreground_color='foreground="red"'
		
		internet="<span $internet_icon_foreground_color></span>$internet_total[$internet_speed]"
	}
	
	if [ "$wifi_i3s" = null ]; then
		wifi=""
	elif [ "$wifi_i3s" -lt 25 ]; then
		wifi="<span foreground=\"#ff00ff\">$wifi</span>"
	elif [ "$wifi_i3s" -lt 50 ]; then
		wifi="<span foreground=\"red\">$wifi</span>"
	elif [ "$wifi_i3s" -lt 75 ]; then
		wifi="<span foreground=\"#ffffcc\">$wifi</span>"
	else
		wifi="  "
	fi
	
	# cell: "  "
	
	# bluetooth: "  "
	blt=
	
	audio_out_dev="$(echo $audio_i3s | cut -d ": " -f 1)"
	if [ "$audio_out_dev" = "Dummy Output" ]; then
		audio=""
	else
		audio_out_vol="$(echo $audio_i3s | cut -d ": " -f 2 | cut -d % -f 1)"
		if [ "$audio_out_vol" -eq 100 ]; then
			audio="  "
		elif [ "$audio_out_vol" -eq 0 ]; then
			audio="  "
		elif [ "$audio_out_vol" -lt 10 ]; then
			audio="<span foreground=\"red\">  </span>"
		elif [ "$audio_out_vol" -lt 20 ]; then
			audio="<span foreground=\"#ffffcc\">  </span>"
		elif [ "$audio_out_vol" -lt 50 ]; then
			audio="<span foreground=\"#ffffcc\">  </span>"
		else
			audio="<span foreground=\"#ffffcc\">  </span>"
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
	
	# screen recording indicator:
	scr=""
	[ "$scrrec" = yes ] && scr="<span foreground=\"red\">⬤  </span>"
	
	echo "  $cpu$mem  $disk$backup$pm$bat  $gnunet$internet  $wifi$cell$blt$audio$mic$cam$scr$time_i3s" || exit 1
done
