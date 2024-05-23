[ -f "$HOME/.local/apps/codev/uninstall.sh" ] && sh "$HOME/.local/apps/codev/uninstall.sh"

command -v jina > /dev/null 2>&1 || {
	# download and install Jina
}

project_dir="$(dirname "$0")"

jina "$project_dir"

mkdir -p "$HOME/.local/apps/codev"
ln "$project_dir/.cache/jina/out/codev/*" "$HOME/.local/apps/codev/"

mkdir -p "$HOME/.local/bin"
echo '#!/usr/bin/sh
export LD_LIBRARY_PATH=.
exec "$HOME/.local/apps/codev/codev"
' > "$HOME/.local/bin/codev"
chmod +x "$HOME/.local/bin/codev"

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
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,16 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,24 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,32 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,40 H 56"/>
	<path style="fill:none;stroke:#aaaaaa;stroke-width:2;stroke-linecap" d="M 24,48 H 56"/>
</svg>
__EOF__

project_path_hash="$(echo -n "$project_dir" | md5sum | cut -d ' ' -f1)"

cat <<-__EOF__ > "$HOME/.local/apps/codev/uninstall.sh"
rm ~/.local/bin/codev
rm ~/.local/share/applications/codev.desktop
rm ~/.local/share/icons/hicolor/scalable/apps/codev.svg
rm -r ~/.local/apps/codev
ospkg-deb remove jina-$project_path_hash
__EOF__
