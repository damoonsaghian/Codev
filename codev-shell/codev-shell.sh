#!/usr/bin/env sh
script_dir="$(dirname "$(realpath "$0")")"

export PATH="$PATH:/$HOME/.local/bin"
export PAGER=less
export SHELL="/usr/bin/bash --noprofile --norc -i \"$script_dir\"/bashrc.sh"

umask 022

cd "$HOME"

text_shell() {
	# ask:
	# , auto repair (spm update)
	# , backup
	# , copy projects
	# , shell
	bash --noprofile --norc -i "$script_dir"/bash-profile.sh
}

if [ "$(tty)" = "/dev/tty1" ]; then
	qml6 "$script_dir"/main.qml || text_shell
else
	text_shell
fi
