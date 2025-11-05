script_dir="$(dirname "$(realpath "$0")")"

for path in /usr/share/bash/profile/*.sh; do
	[ -r "$path" ] && . "$path"
done
unset path

# ask user for lockscreen password, and if correct continue

TMOUT=600 # this is for timeout when in bash prompt
_precmd() {
	# this is for timeout for long running processes
	[ -n "$START" ] && [ "$((SECONDS-START-TMOUT))" -ge 0 ] && exit
	START="$SECONDS"
}
PROMPT_COMMAND=_precmd

. "$script_dir"/bashrc.sh
