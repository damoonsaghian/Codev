if command -v dpkg 1>/dev/null; then
	spm add "$(dirname "$(realpath $0)")" "gir1.2-gtksource-5, gir1.2-webkit-6.0, gir1.2-poppler-0.18, \
		libavif-gdk-pixbuf, webp-pixbuf-loader, librsvg2-common, \
		gir1.2-gstreamer-1.0, gstreamer1.0-pipewire, \
		libgtk-4-media-gstreamer, gstreamer1.0-plugins-good, gstreamer1.0-plugins-ugly, gstreamer1.0-libav, \
		libarchive-tools, gvfs, dosfstools, exfatprogs, btrfs-progs, gnunet"
	echo "required packages:"
	echo "\tgir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18"
	echo "\tlibavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common"
	echo "\tgir1.2-gstreamer-1.0 gstreamer1.0-pipewire"
	echo "\tlibgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav"
	echo "\tlibarchive-tools gvfs dosfstools exfatprogs btrfs-progs gnunet"
fi

# libjxl in Debian is old, and does not have gdk-pixbuf loader
# https://packages.debian.org/source/bookworm/jpeg-xl

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

project_dir="$(dirname "$0")"

mkdir -p "$project_dir/.cache/spm"

ln "$project_dir"/codev/* "$project_dir"/.cache/spm/

echo '#!/bin/sh
this_script_real_path="$(readlink $0)"
exec python3 "$(dirname "$this_script_real_path")"
' > "$project_dir"/.cache/spm/0
chmod +x "$project_dir"/.cache/spm/0
