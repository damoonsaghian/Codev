osp-deb libgtk-4-dev libgtksourceview-5-dev libwebkitgtk-6.0-dev libpoppler-glib-dev libgstreamer1.0-dev \
	gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libjxl-gdk-pixbuf libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	libarchive-tools gvfs dosfstools exfatprogs btrfs-progs gnunet

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

printf "-lgtk-4 -lgtksourceview-5 -lwebkitgtk-6 -lpoppler-glib -llibgstreamer-1.0"
