for path in /usr/share/zsh/*.sh; do
	[ -r "$path" ] && . "$path"
done
unset path

# ask user for lockscreen password, and if correct continue

# to prevent BadUSB, lock when a new input device is connected
