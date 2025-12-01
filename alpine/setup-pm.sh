# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
# spm list ...
# spm install ...
# spm remove ...
# spm update
# spm new
' > /usr/local/bin/spm
# doas rules for "spm new"

# cp this dir to /usr/local/share/spm

printf '#!/usr/bin/env sh
exec sh /usr/local/share/spm/new.sh
' > "$new_root"/usr/local/bin/spm-new
chmod +x "$new_root"/usr/local/bin/spm-new

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
