apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland

cp /mnt/comshell/di/{sway.conf,sway-status.sh} /usr/local/share/

echo -n '' > /usr/local/share/i3status.conf

echo -n '
apps = "comshell" +

bemenu = "bemenu --grab --bottom --margin 1 --line-height 12 --fn \"sans 10.5\""
bmenu += " --tb #4285F4 --tf #ffffff --hb #4285F4 --hf #ffffff --sb #4285F4 --sf #ffffff"
bmenu += " --fb #222222 --ff #ffffff --cb #222222 --cf #ffffff --nb #222222 --nf #ffffff"
bmenu += " --ignorecase -p applications"

app =

# if app is comshell
# "swaymsg \"workspace Comshell; exec comshell || python3 /usr/local/share/comshell-py/ || python3 /usr/local/share/swapps.py\""

# if app in not empty
# "swaymsg \"workspace ${app}; sway [con_id=__focused__] focus\" || swaymsg exec ${app}"
' > /usr/local/share/swapps.py
