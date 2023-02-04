pick() {
	# the list of choices with the indents removed
	local list="$(echo "$2" | sed -r 's/^[[:blank:]]+//')"
	local count="$(echo "$2" | wc -l)"
	local index=1
	local key=
	
	local terminal_height="$(stty size | cut -d ' ' -f1)"
	local max_height=15
	[ $max_height -gt $terminal_height ] && max_height=$terminal_height
	local scrolled=false
	[ $((count+2)) -gt $max_height ] && scrolled=true
	
	# if a default option is provided, find its index
	[ -z "$3" ] || {
		i="$(printf "$list" | sed -n "/$3/=" | head -n 1)"
		[ -z "$i" ] || index=i
	}
	
	while true; do
		# print the lines, highlight the selected one
		printf "$list" | {
			i=1
			j=$((index-max_height/2))
			while read line; do
				d=$((i-index))
				$scrolled && { [ $i -lt $j ] || [ $i -gt $((j+max_height-2)) ]; } && break
				
				if [ $i = $index ]; then
					printf "  \e[7m$line\e[0m\n" # highlight
				else
					printf "  $line\n"
				fi
				i=$((i+1))
			done
		}

		if [ $index -eq 0 ]; then
			printf "\e[7mexit\e[0m\n" # highlighted
		else
			printf "\e[8mexit\e[0m\n" # hidden
		fi
		
		read -s -n1 key # wait for user to press a key
		
		# if key is empty, it means the read delimiter, ie the "enter" key was pressed
		[ -z "$key" ] && break

		if [ "$key" = "\177" ]; then
			index=0
		elif [ "$key" = " " ]; then
			index=$((index+1))
			[ $index -gt $count ] && i=1
		else
			# find the next line which its first character is "$key", and put the line's number in "index"
			i=index
			while true; do
				i=$((i+1))
				[ $i -gt $count ] && i=1
				[ $i -eq $index ] && break
				if [ "$(echo "$list" | sed -n "$i"p | cut -c1)" = "$key" ]; then
					index=i
					break
				fi
			done
		fi
		
		if $scrolled; then
			echo -en "\e[$((max_height-1))A"
		else
			echo -en "\e[$((count+1))A" # go up to the beginning to re'render
		fi
	done
	
	[ $index -eq 0 ] && { echo; exit; }
	selected_line="$(echo "$list" | sed -n "${index}p")"
	eval "$1=\"$selected_line\""
}
