set -e

. /mnt/comshell/di/bootloader.sh

apt-get update
# some statndard packages, plus wget and python
apt-get install --no-install-recommends --yes libnss-systemd systemd-timesyncd file bash-completion \
  wget2 python3-minimal libpython3-stdlib

apt-get install --no-install-recommends --yes wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

. /mnt/comshell/di/login.sh

. /mnt/comshell/di/system.sh

. /mnt/comshell/di/style.sh

. /mnt/comshell/di/sd.sh

apt-get install --no-install-recommends --yes sway swayidle swaylock xwayland psmisc gir1.2-gnomedesktop-4.0
cp /mnt/comshell/di/{sway.conf,sway-status.py,swapps.py} /usr/local/share/

apt-get install --no-install-recommends --yes openssh-client gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency (through libgpgme11)
cp /mnt/comshell/di/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

apt-get install --no-install-recommends --yes python3-gi python3-gi-cairo \
  gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  libarchive-tools
cp -r /mnt/comshell/comshell-py /usr/local/share/
