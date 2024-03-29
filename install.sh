command -v jina > /dev/null 2>&1 || {
	# download and install Jina
}

project_dir="$(dirname "$0")"

sh "$project_dir/gui.sh" &> /dev/null

jina "$project_dir"

mkdir -p "$HOME/.local/packages/codev"
ln "$project_dir/.cache/jina/out/*" "$HOME/.local/packages/codev/"
mkdir -p "$HOME/.local/bin"
echo '#!/usr/bin/sh
LD_LIBRARY_PATH=. $HOME/.local/packages/codev/codev
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
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,14 H 41"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,23 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,32 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 30,41 H 48"/>
	<path style="fill:none;stroke:#555555;stroke-width:2;stroke-linecap" d="M 25,50 H 41"/>
</svg>
__EOF__

cat <<-'__EOF__' > "$HOME/.local/packages/codev/uninstall.sh"
rm "$HOME/.local/bin/codev"
rm "$HOME/.local/share/applications/codev.desktop"
rm "$HOME/.local/share/icons/hicolor/scalable/apps/codev.svg"
rm -r "$HOME/.local/packages/codev"
exit
__EOF__
