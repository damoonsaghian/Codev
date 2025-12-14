# ask user for lockscreen password, and if correct continue

TMOUT=600 # this is for timeout when in bash prompt
_precmd() {
	# this is for timeout for long running processes
	[ -n "$START" ] && [ "$((SECONDS-START-TMOUT))" -ge 0 ] && exit
	START="$SECONDS"
}
PROMPT_COMMAND=_precmd

if [ "$CODEVSHELL_PROMPT" = true ]; then
	PS1=""
	_run_cmd() {
		echo "$BASH_COMMAND" >> /tmp/codevshell-command
		clear
	}	
else
	PS1="\e[7m\[${PWD}\]\[$(printf '%0.s ' $(seq 1 $((COLUMNS - ${#PWD})) ))\]\e[0m\n"
	_run_cmd() {
		printf '%0.s-' $(seq 1 $COLUMNS)
		echo
		$BASH_COMMAND
	}
fi
trap _run_cmd DEBUG

PS2=""

[ -n "$CODEVSHELL_COMMAND" = true ] && {
	. /tmp/codevshell-term-env
	$CODEVSHELL_COMMAND
	export -p > /tmp/codevshell-term-env
	exit
}
