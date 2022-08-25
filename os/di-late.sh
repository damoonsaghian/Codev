set -e

apt-get update
apt-get install --no-install-recommends --yes systemd-resolved iwd wireless-regdb modemmanager bluez rfkill \
  wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth \
  dbus-user-session kbd pkexec \
  sway swayidle swaylock xwayland \
  fonts-hack fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji materia-gtk-theme \
  python3-gi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 python3-cairocffi \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  dosfstools exfatprogs btrfs-progs udisks2 polkitd \
  libarchive-tools \
  openssh-client wget2 gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency (through libgpgme11)
# kbd is needed for its chvt and openvt

[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

. /mnt/comshell/os/di-late-bootloader.sh

. /mnt/comshell/os/di-late-su.sh

cp /mnt/comshell/os/sd.sh /usr/local/share/
echo -n 'set -e
format () {
  # if it is not already formated with BTRFS
  mkfs.btrfs /dev/"$1"
}
mount () {
  mkdir -p /run/mount/"$1"
  mount /dev/$1 /run/mount/"$1"
  cp --no-clobber --preserve=all /home/ /run/mount/"$1"
}
case "$1" in
  format) shift; format "$@" ;;
  mount) shift; mount "$@" ;;
  *) echo "usage: sd-internal format/mount"
    exit 1 ;;
esac
' > /usr/local/share/sd-internal.sh

cp /mnt/comshell/os/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

. /mnt/comshell/os/di-late-style.sh

. /mnt/comshell/os/di-late-system.sh

cp /mnt/comshell/os/{sway.conf,status.py,swapps.py} /usr/local/share/

cp -r /mnt/comshell/comshell-py /usr/local/share/
