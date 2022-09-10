apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland j4-dmenu-desktop

cp /mnt/comshell/di/{sway.conf,sway-status.sh} /usr/local/share/

echo -n '' > /usr/local/share/i3status.conf

echo -n '#!/bin/sh
bemenu="bemenu --ignorecase --scrollbar autohide --grab --bottom --fn \"sans 10.5\""
j4-dmenu-desktop --dmenu="$bemenu"
' > /usr/local/bin/swapps
chmod +x /usr/local/bin/swapps
