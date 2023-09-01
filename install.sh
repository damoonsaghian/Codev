apt-get install gjs gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
	gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libjxl-gdk-pixbuf libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	gvfs-backends dosfstools exfatprogs btrfs-progs gnunet

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

cp -r "$(dirname "$0")"/src.gjs/* /usr/local/share/codev/

echo -n '#!/bin/sh
gjs /usr/local/share/codev/0.js
' > /usr/local/bin/codev
chmod +x /usr/local/bin/codev

mkdir -p /usr/local/share/applications
cat <<-__EOF__ > /usr/local/share/applications/codev.desktop
[Desktop Entry]
Type=Application
Name=Codev
Icon=codev
Exec=codev
StartupNotify=true
__EOF__

cat <<-__EOF__ > /usr/local/share/icons/hicolor/scalable/apps/codev.svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64">
	<rect style="fill:#dddddd" width="56" height="48" x="4" y="8"/>
	<rect style="fill:#aaaaaa" width="16" height="48" x="4" y="8"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,14 H 41"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,23 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,32 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,41 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,50 H 41"/>
</svg>
__EOF__

first_user="$(id -un 1000)"
usermod -aG gnunet "$first_user"
su -c "touch \"/home/$first_user/.config/gnunet.conf\"" "$first_user"
echo -n '[ats]
WLAN_QUOTA_IN = unlimited
WLAN_QUOTA_OUT = unlimited
WAN_QUOTA_IN = unlimited
WAN_QUOTA_OUT = unlimited
' >> "/home/$first_user/.config/gnunet.conf"
