# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
script_dir="$(dirname "$(realpath "$0")")"

case "$1" in
list) shift; apk list $@ ;;
install) shift; apk add $@ ;;
remove) shift; apk del $@ ;;
update)
	apk upgrade
	
	[ -f /usr/local/bin/quickshell ] && if apk add quickshell &>/dev/null; then
		apk del quickshell-git
		# remove quickshell from /usr/local/
	else
		"$script_dir"/quickshell.sh
	fi
	
	# alpine codev-util codev-shell codev
	;;
new)
	if [ "$2" = removable ]; then
		sh /usr/local/share/spm/new-removable.sh
	else
		sh /usr/local/share/spm/new.sh
	fi
	;;
esac
' > /usr/local/share/spm/spm.sh
chmod +x /usr/local/share/spm/spm.sh
ln -s /usr/local/share/spm/spm.sh /usr/local/bin/spm
# doas rules for /usr/local/share/spm/spm.sh

mkdir -p "$new_root"/usr/local/share/spm/
cp "$script_dir"/* "$new_root"/usr/local/share/spm/

# apk-autoupdate
# autoupdate service
# service timer: 5min after boot, every 24h
# rc_new add crond
printf '#!/usr/bin/env sh
metered_connection() {
	#nmcli --terse --fields GENERAL.METERED dev show | grep --quiet "yes"
	#dbus: org.freedesktop.NetworkManager Metered
}
metered_connection && exit 0
# if plugged
# inhibit suspend/shutdown when an upgrade is in progress
# if during autoupdate an error occures: echo error > /var/cache/autoupdate-status

# fwupd
' > /usr/local/bin/autoupdate
chmod +x /usr/local/bin/autoupdate
