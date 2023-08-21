# for implementing a prototype of Codev, it seems that the best tool at hand is PyGObject
# Python provides a simple consistent API for almost anything

apt-get --yes install gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
	gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libjxl-gdk-pixbuf libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	python3-gi python3-gi-cairo libarchive13 gnunet \
	gvfs-backends dosfstools exfatprogs btrfs-progs libarchive13 gnunet

# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

project_dir="$(dirname "$0")"
cp -r "$project_dir"/src.py/* /usr/local/share/codev/
cat <<-__EOF__ > /usr/local/bin/codev
#!/bin/sh
python3 /usr/local/share/codev/
__EOF__
chmod +x /usr/local/bin/codev
