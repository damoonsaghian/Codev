apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland psmisc tofi foot

cp /mnt/comshell/di/{sway.conf,sway-status.py} /usr/local/share/

echo -n '[Desktop Entry]
Type=Application
Name=Terminal
Exec=footclient
StartupNotify=true
' > /usr/local/share/applications/terminal.desktop
echo -n '[Desktop Entry]
NoDisplay=true
' | tee /usr/local/share/applications/{foot,footclient,foot-server}.desktop
echo -n 'font=monospace:size=10.5
[scrollback]
indicator-position=none
[cursor]
blink=yes
[colors]
background=f8f8f8
foreground=2A2B32
selection-foreground=f8f8f8
selection-background=2A2B32
regular0=20201d  # black
regular1=d73737  # red
regular2=60ac39  # green
regular3=cfb017  # yellow
regular4=6684e1  # blue
regular5=b854d4  # magenta
regular6=1fad83  # cyan
regular7=fefbec  # white
bright0=7d7a68
bright1=d73737
bright2=60ac39
bright3=cfb017
bright4=6684e1
bright5=b854d4
bright6=1fad83
bright7=fefbec
' > /usr/local/share/foot.cfg

echo -n 'history = false
require-match = true
drun-launch = false
font = monospace
background-color = #000A
prompt-text = ""
width = 100%
height = 100%
border-width = 0
outline-width = 0
padding-left = 35%
padding-right = 35%
padding-top = 20%
padding-bottom = 20%
result-spacing = 25
' > /usr/local/share/tofi.cfg

