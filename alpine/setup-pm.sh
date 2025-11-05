# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
# spm list ...
# spm install ...
# spm remove ...
# spm update
# spm new
' > /usr/local/bin/spm
# doas rules for "spm new"

# cp thid dir to /usr/local/share/spm
ln -s /usr/local/share/spm/new /usr/local/bin/spm-new

# apk-autoupdate
# autoupdate service
# service timer: 5min after boot, every 24h
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
