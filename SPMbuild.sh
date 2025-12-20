pkg=codev-util

spm_import gnunet
spm_import cryptsetup

# doas rules for sd.sh

# https://github.com/eggert/tz
# only produce "right" timezones
echo '#!/bin/sh
system tz guess
' > /usr/share/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /usr/share/NetworkManager/dispatcher.d/09-dispatch-script

pkg=codev-shell

spm_import bash
spm_import qt
spm_import quickshell
spm_import codev

pkg=codev

spm_import qt
spm_import quickshell # needed for Process qml type
spm_import codev-util
spm_import curl
spm_import mauikit-filebrowsing
spm_import archive

spm_xcript inst/app codev

ln "$pkg_dir/.data/codev.svg" "$pkg_dir/.cache/spm/$ARCH/app/codev.svg"
