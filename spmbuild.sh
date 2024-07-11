project_dir="$(dirname "$0")"

spm build gtk gtksourceview webkitgtk poppler gstreamer
# hardlink these libs into $project_dir/.cache/spm/

spm install python-gobject \
	gst-plugin-pipewire gst-plugins-good gst-plugins-ugly gst-libav \
	gvfs gnunet

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

mkdir -p "$project_dir/.cache/spm"

ln "$project_dir"/codev/* "$project_dir"/.cache/spm/

echo '#!/bin/sh
this_dir="$(dirname "$(realpath "$0")")"
exec python3 "$this_dir"
' > "$project_dir"/.cache/spm/0
chmod +x "$project_dir"/.cache/spm/0
