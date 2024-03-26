command -v jina > /dev/null 2>&1 || sudo apt-get install jina || {
	echo 'to build Codev, Jina must be installed on the system'
	exit 1
}

sudo apt-get install libgtk-4-dev libgtk-4-1 libgtksourceview-5-dev libgtksourceview-5-0 \
	libwebkitgtk-6.0-dev libwebkitgtk-6.0-4 libpoppler-glib-dev libpoppler-glib8 \
	libgstreamer1.0-dev libgstreamer1.0-0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libjxl-gdk-pixbuf libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	libarchive-tools gvfs dosfstools exfatprogs btrfs-progs gnunet

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

project_dir="$(dirname "$0")"
jina "$project_dir" -lgtk-4,gtksourceview-5,webkitgtk-6,poppler-glib,libgstreamer-1.0
cp "$project_dir/.cache/jina/bin" /usr/local/bin/codev

sudo apt-get remove --auto-remove --purge \
	libgtk-4-dev libgtksourceview-5-dev libwebkitgtk-6.0-dev libpoppler-glib-dev libgstreamer1.0-dev

mkdir -p "$HOME/.local/share/applications"
cat <<-__EOF__ > "$HOME/.local/share/applications/codev.desktop"
[Desktop Entry]
Type=Application
Name=Codev
Icon=codev
Exec=codev
StartupNotify=true
__EOF__

cat <<-__EOF__ > "$HOME/.local/share/icons/hicolor/scalable/apps/codev.svg"
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
