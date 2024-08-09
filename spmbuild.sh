project_dir="$(dirname "$0")"

spm add python-gobject gtk gtksourceview webkitgtk poppler \
	gstreamer gst-plugin-pipewire gst-plugins-good gst-plugins-ugly gst-libav \
	gvfs gnunet
# hardlink the required files into $project_dir/.cache/spm/

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

mkdir -p "$project_dir/.cache/spm"

ln "$project_dir"/codev/* "$project_dir"/.cache/spm/

echo '#!/bin/sh
this_dir="$(dirname "$(realpath "$0")")"
export LD_LIBRARY_PATH=.
PATH="$this_dir"
exec python3 "$this_dir"
' > "$project_dir"/.cache/spm/0
chmod +x "$project_dir"/.cache/spm/0

mkdir -p "$HOME/.local/share/applications"
cat <<-__EOF__ > "$project_dir"/.cache/spm/codev.desktop
[Desktop Entry]
Type=Application
Name=Codev
Icon=codev
Exec=codev
StartupNotify=true
__EOF__

cat <<-__EOF__ > "$project_dir"/.cache/spm/icons/hicolor/scalable/apps/codev.svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64">
	<rect style="fill:#dddddd" width="56" height="48" x="4" y="8"/>
	<rect style="fill:#aaaaaa" width="16" height="48" x="4" y="8"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,16 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,24 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,32 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,40 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,48 H 56"/>
</svg>
__EOF__
