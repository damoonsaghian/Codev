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
	# , shell (password will be requested first)
	
	# last two must be run with: sudo -u 1000 ...
	
	# ask for password, and if correct:
	# doas -u 1000 bash --noprofile --norc -i "$script_dir"/bash-profile.sh
}

if [ "$(tty)" = "/dev/tty1" ]; then
	# qmlrun "$script_dir"/main.qml
	# if failed run text_shell
else
	# run text_shell
fi
