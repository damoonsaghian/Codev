command -v jina || apt-get install jina || echo "Jina compiler is needed, to build Codev"

apt-get install libgtk-4-dev libgtk-4-1 libgtksourceview-5-dev libgtksourceview-5-0 \
	libwebkitgtk-6.0-dev libwebkitgtk-6.0-4 libpoppler-glib-dev libpoppler-glib8 \
	libudisks2-dev libudisks2-0 dosfstools exfatprogs btrfs-progs gvfs \
	libgstreamer1.0-dev libgstreamer1.0-0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libavif-gdk-pixbuf heif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	libarchive-dev libarchive13 gnunet

# there is no .vapi file for webkitgtk6 yet (libwebkitgtk-6.0-dev, valac-0.56-vapi)
# https://wiki.gnome.org/Projects/Vala/Bindings#Generating_the_VAPI_File
# https://manpages.debian.org/unstable/valac/vapigen.1.en.html
# https://manpages.debian.org/unstable/valac/valac.1.en.html

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

# libjxl is compiled with gdk-pixbuf loader disabled, until skcms enters Debian

cd "$(dirname "$0")"
jina build
cp .cache/jina/codev /usr/local/bin/

apt-get --yes purge libgtk-4-dev libgtksourceview-5-dev libwebkitgtk-6.0-dev libpoppler-glib-dev \
	libudisks2-dev libgstreamer1.0-dev libarchive-dev
apt-get --yes --purge autoremove
apt-get --yes autoclean

mkdir -p /usr/local/share/applications
cat <<-__EOF__ > /usr/local/share/applications/codev.desktop
[Desktop Entry]
Type=Application
Name=Codev
Icon=codev
Exec=/usr/local/bin/codev
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
