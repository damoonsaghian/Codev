apt-get -qq install sway swayidle xwayland python3-gi gir1.2-gtk-4.0 gir1.2-vte-3.91 \
	gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18 \
	libavif-gdk-pixbuf webp-pixbuf-loader librsvg2-common \
	gir1.2-gstreamer-1.0 gstreamer1.0-pipewire \
	libgtk-4-media-gstreamer gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav \
	libarchive-tools gvfs dosfstools exfatprogs btrfs-progs gnunet

# libjxl in Debian is old, and does not have gdk-pixbuf loader
# https://packages.debian.org/source/bookworm/jpeg-xl
#
# plugins-good contains support for mp4/matroska/webm containers, plus mp3 and vpx
# libav is needed till
# , h264(openh264), h265(libde265), and aac(fdk-aac) go into plugins-ugly
# , and av1(aom-libs) goes into plugins-good

# this way, Sway's config can't be changed by a normal user
# this means that, swayidle can't be disabled by a normal user (see sway.conf)
echo -n '# run sway (if this script is not called by root or a display manager, and this is the first tty)
if [ ! "$(id -u)" = 0 ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
	[ -f "$HOME/.profile" ] && . "$HOME/.profile"
	exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/zz-sway.sh

cp /mnt/os/sway.conf /mnt/os/swapps.py /mnt/os/terminal.py /usr/local/share/
cp /mnt/codev /usr/local/share/

mkdir -p /usr/local/share/applications
echo -n '[Desktop Entry]
Type=Application
Name=Terminal
Icon=terminal
Exec=python3 /usr/local/share/terminal.py
StartupNotify=true
' > /usr/local/share/applications/terminal.desktop
mkdir -p /usr/local/share/icons/hicolor/scalable/apps
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<svg height="128px" viewBox="0 0 128 128" width="128px">
	<path d="m 20 12 h 88 c 4.4 0 8 3.6 8 8 v 80 c 0 4.4 -3.6 8 -8 8 h -88 c -4.4 0 -8 -3.6 -8 -8 v -80 c 0 -4.4 3.6 -8 8 -8 z m 0 0" fill="#666666"/>
	<path d="m 20 14 h 88 c 3.3 0 6 2.7 6 6 v 80 c 0 3.3 -2.7 6 -6 6 h -88 c -3.3 0 -6 -2.7 -6 -6 v -80 c 0 -3.3 2.7 -6 6 -6 z m 0 0" fill="#222222"/>
	<g fill="#dddddd">
		<path d="m 46 40.9 l -14 -7.6 v 4.7 l 9.7 4.6 v 0.1 l -9.7 5.2 v 4.7 l 14 -8.2 z m 0 0"/>
		<path d="m 50 56 v 4 h 16 v -4 z m 0 0"/>
	</g>
</svg>
' > /usr/local/share/icons/hicolor/scalable/apps/terminal.svg

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don’t have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# "https://github.com/iaolo/iA-Fonts/tree/master/iA%20Writer%20Quattro"
# "https://input.djr.com/"
apt-get -qq install fonts-noto-core fonts-hack
mkdir -p /etc/fonts
echo -n '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
	<selectfont>
		<rejectfont>
			<pattern><patelt name="family"><string>NotoNastaliqUrdu</string></patelt></pattern>
			<pattern><patelt name="family"><string>NotoKufiArabic</string></patelt></pattern>
			<pattern><patelt name="family"><string>NotoNaskhArabic</string></patelt></pattern>
		</rejectfont>
	</selectfont>
	<alias>
		<family>serif</family>
		<prefer><family>NotoSerif</family></prefer>
	</alias>
	<alias>
		<family>sans</family>
		<prefer><family>NotoSans</family></prefer>
	</alias>
	<alias>
		<family>monospace</family>
		<prefer><family>Hack</family></prefer>
	</alias>
</fontconfig>
' > /etc/fonts/local.conf
