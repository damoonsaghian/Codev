project_dir="$(dirname "$0")"

spm_import $gnunet_namespace python-gobject
spm_import $gnunet_namespace gtk
spm_import $gnunet_namespace gtksourceview
spm_import $gnunet_namespace gtkwebkit
spm_import $gnunet_namespace gstreamer
spm_import $gnunet_namespace gvfs
spm_import $gnunet_namespace lsh

mkdir -p "$project_dir/.cache/spm"

ln "$project_dir/codev/"* "$project_dir/.cache/spm/$ARCH/"

echo '#!/usr/bin/env sh
python3 "$(dirname "$(realpath "$0")")/../"
' > "$project_dir/.cache/spm/$ARCH/exec/codev"
chmod +x "$project_dir/.cache/spm/$ARCH/exec/codev"

spm_xport inst/app codev

cat <<-__EOF__ > "$project_dir/.cache/spm/$ARCH/app/codev.svg"
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
