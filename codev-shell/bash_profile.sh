script_dir="$(dirname "$(realpath "$0")")"

# ask:
# , auto repair (if no internet and no LAN, setup network; spm update; also if not on tty1, restart tty1)
# , backup
# , copy projects

# ask user for lockscreen password, and if correct continue

TMOUT=600 # this is for timeout when in bash prompt
_precmd() {
	# this is for timeout for long running processes
	[ -n "$START" ] && [ "$((SECONDS-START-TMOUT))" -ge 0 ] && exit
	START="$SECONDS"
}
PROMPT_COMMAND=_precmd

. "$script_dir"/bashrc.sh
