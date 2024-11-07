project_dir="$(dirname "$0")"

$PKG python-gobject
$PKG gtk
$PKG gtksourceview
$PKG gtkwebkit
$PKG gstreamer
$PKG gvfs
$PKG lsh
# hardlink the required files into $project_dir/.cache/spm/

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
