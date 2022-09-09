apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland foot fuzzel
cp /mnt/comshell/di/{sway.conf,sway-status.py} /usr/local/share/

echo -n 'font=monospace:size=10.5
dpi-aware=no
initial-window-size-chars=120x55
pad=0x0 center
[scrollback]
indicator-position=none
[cursor]
blink=yes
[colors]
# alpha=1.0
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
' > /usr/local/share/foot.ini
