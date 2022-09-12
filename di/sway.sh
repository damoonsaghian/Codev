apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland

cp /mnt/comshell/di/{sway.conf,sway-status.sh} /usr/local/share/

echo -n '' > /usr/local/share/i3status.conf

echo -n '
bemenu = "bemenu --ignorecase --grab --bottom --fn \"sans 10.5\""
bmenu += "--tb #4285F4 --tf #ffffff --hb #4285F4 --hf #ffffff --sb #4285F4 --sf #ffffff"
bmenu += "--fb #222222 --ff #ffffff --cb #222222 --cf #ffffff --nb #222222 --nf #ffffff"
bmenu += "-p applications"
' > /usr/local/share/swapps.py
