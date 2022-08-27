set -e

apt-get update

. /mnt/comshell/di/bootloader.sh

. /mnt/comshell/di/sd.sh

. /mnt/comshell/di/style.sh

. /mnt/comshell/di/login.sh

. /mnt/comshell/di/system.sh

apt-get install --no-install-recommends --yes wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

apt-get install --no-install-recommends --yes openssh-client wget2 gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency (through libgpgme11)
cp /mnt/comshell/os/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland
cp /mnt/comshell/os/{sway.conf,status.py,swapps.py} /usr/local/share/
mkdir -p /usr/local/lib/systemd/user
echo -n '[Unit]
Description=sway
[Service]
ExecStart=/bin/sh -c "[ $(id -u) = 0 ] || sway -c /usr/local/share/sway.conf"
Nice=19
KillMode=process
KillSignal=SIGINT
[Install]
WantedBy=default.target
' > /usr/local/lib/systemd/user/sway.service
systemctl --global enable sway.service

apt-get install --no-install-recommends --yes \
  python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 python3-cairocffi \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  libarchive-tools
cp -r /mnt/comshell/comshell-py /usr/local/share/
