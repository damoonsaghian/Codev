set -e

. /mnt/comshell/di/bootloader.sh

apt-get update
# some standard packages, plus polkit, pkexec , iproute, wget and python-gi
apt-get install --no-install-recommends --yes libnss-systemd systemd-timesyncd file bash-completion \
  polkitd pkexec iproute2 wget2 python3-gi
ln -s /usr/bin/wget2 /usr/local/bin/wget

apt-get install --no-install-recommends --yes wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
[ -f /etc/alsa/conf.d/99-pipewire-default.conf ] ||
  cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

. /mnt/comshell/di/login.sh

. /mnt/comshell/di/system.sh

. /mnt/comshell/di/style.sh

. /mnt/comshell/di/sway.sh

echo -n '#!/usr/bin/pkexec /bin/sh
mkdir -p /run/mount/"$1"
result=$"(findmnt --mountpoint /run/mount/"$1")"
[ -z "$result" ] && mount -o nosuid,nodev,noexec,nofail /dev/$1 /run/mount/"$1"
cp --no-clobber --preserve=all /home/ /run/mount/"$1"
' > /usr/local/bin/mount-internal
chmod +x /usr/local/bin/mount-internal

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.mount.internal">
    <description>mount internal storage devices</description>
    <message>mount internal storage devices</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/mount-internal</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.mount.policy

apt-get install --no-install-recommends --yes openssh-client gpg attr
# installing gpg prevents wget2 to install the whole of gnupg as dependency (through libgpgme11)
cp /mnt/comshell/di/codev /usr/local/bin/
chmod +x /usr/local/bin/codev

apt-get install --no-install-recommends --yes  python3-gi-cairo \
  gir1.2-gtksource-5 gir1.2-webkit2-5.0 gir1.2-poppler-0.18 gir1.2-vte-3.91 \
  libgtk-4-media-gstreamer gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav heif-gdk-pixbuf \
  libarchive-tools udisks2 dosfstools exfatprogs btrfs-progs
cp -r /mnt/comshell/comshell-py /usr/local/share/
mkdir -p /usr/local/share/applications
echo -n '[Desktop Entry]
Type=Application
Name=Comshell
Exec=sh -c "swaymsg workspace 1:comshell; comshell || python3 /usr/local/share/comshell-py/"
StartupNotify=true
' > /usr/local/share/applications/comshell.desktop
