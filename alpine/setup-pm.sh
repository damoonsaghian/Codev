# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
case "$1" in
list) ;;
install) ;;
remove) ;;
update)
	apk upgrade
	
	[ -f /usr/local/bin/quickshell ] && if apk add quickshell &>/dev/null; then
		# apk del quickshell-virtual
		# remove quickshell from /usr/local/
	else
		# build and install quickshell from git
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
' > /usr/local/bin/spm
chmod +x /usr/local/bin/spm
# doas rules for spm

mkdir -p "$new_root"/usr/local/share/spm/
cp -r "$script_dir"/new* "$script_dir"/setup-* "$new_root"/usr/local/share/spm/

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
