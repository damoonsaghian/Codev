PS1="\e[7m \w \e[0m\n> "

_codevshell_prompt() {
	echo "$BASH_COMMAND" >> /tmp/codevshell-command
	clear
}
[ "$CODEVSHELL_PROMPT" = true ] && {
	PS1="\e[7m \w \e[0m\n> "
	trap _codevshell_prompt DEBUG
}

[ -n "$CODEVSHELL_COMMAND" = true ] && {
	. /tmp/codevshell-term-env
	$CODEVSHELL_COMMAND
	export -p > /tmp/codevshell-term-env
	exit
}
