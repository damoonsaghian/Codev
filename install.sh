if command -v dpkg 1>/dev/null; then
	spm add "$(dirname "$(realpath $0)")" \
		"lua5.3, lua-lgi, gir1.2-gtk-4.0, gir1.2-gtksource-5, gir1.2-webkit-6.0, gir1.2-poppler-0.18, \
		libavif-gdk-pixbuf, webp-pixbuf-loader, librsvg2-common, \
		gir1.2-gstreamer-1.0, gstreamer1.0-pipewire, \
		libgtk-4-media-gstreamer, gstreamer1.0-plugins-good, gstreamer1.0-plugins-ugly, gstreamer1.0-libav, \
		libarchive-tools, gvfs, dosfstools, exfatprogs, btrfs-progs, gnunet"
	echo "required packages:"
	echo "\tlua5.3 lua-lgi gir1.2-gtk-4.0 gir1.2-gtksource-5 gir1.2-webkit-6.0 gir1.2-poppler-0.18"
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

cat <<-'__EOF__' > "$project_dir/.cache/spm/0"
#!/usr/bin/sh
this_dir = "$(dirname "$(realpath "$0")")"
args="$(printf "'%s', " "$@")"
find "$this_dir" -name '?*.lua' -type f -printf "%P\n" | lua5.3 -e "
	for lua_file_relative_path in io:lines() do
		local dir_part = string.gsub(lua_file_relative_path, '/[^/]+$', '')
		local env = _G
		for subdir in string.gmatch(dir_part, '[^/]+') do
			env[subdir] = {}
			env = env[subdir]
		end
		loadfile('$this_dir'..'/'..lua_file_relative_path, 'bt', env)()
	end
	main($args)
"
__EOF__
chmod +x "$project_dir/.cache/spm/0"

