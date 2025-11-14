# implement "spm" by wrapping apk commands
printf '#!/usr/bin/env sh
# spm list ...
# spm install ...
# spm remove ...
# spm update
# spm new
' > /usr/local/bin/spm
# doas rules for "spm new"

# regenerate UKI, when efistub or ucodes are updated
#
# before spm update/install:
# rm -f /var/cache/uki/*-ucode.img /var/cache/uki/linux*.efi.stub
# [ -f /boot/amd-ucode.img] && ln /boot/amd-ucode.img /var/cache/uki/
# [ -f /boot/intel-ucode.img] && ln /boot/intel-ucode.img /var/cache/uki/
# [ -f /usr/lib/systemd/boot/efi/linux*.efi.stub ] && ln /usr/lib/systemd/boot/efi/linux*.efi.stub /var/cache/uki/
# [ -f /usr/lib/stubbyboot/linux*.efi.stub ] && ln /usr/lib/stubbyboot/linux*.efi.stub /var/cache/uki/
#
# after spm update/install:
# [ -f /boot/amd-ucode.img] && ! [ /boot/amd-ucode.img -ef /var/cache/uki/amd-ucode.img ] && uki_regen_required=true
# [ -f /boot/intel-ucode.img] && ! [ /boot/intel-ucode.img -ef /var/cache/uki/intel-ucode.img ] && uki_regen_required=true
# [ -f /usr/lib/systemd/boot/efi/linux*.efi.stub ] &&
# 	! [ /usr/lib/systemd/boot/efi/linux*.efi.stub -ef /var/cache/uki/linux*.efi.stub ] && uki_regen_required=true
# [ -f /usr/lib/stubbyboot/linux*.efi.stub ] && 
# 	! [ /usr/lib/stubbyboot/linux*.efi.stub -ef /var/cache/uki/linux*.efi.stub ] && uki_regen_required=true
# [ "$uki_regen_required$ = true ] && /etc/kernel-hooks.d/uki.hook
# rm -f /var/cache/uki/*-ucode.img /var/cache/uki/linux*.efi.stub

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
