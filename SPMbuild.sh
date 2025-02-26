spm_import $gnunet_namespace jina
spm_import $gnunet_namespace gnunet
spm_import $gnunet_namespace ssh
spm_import $gnunet_namespace gvfs
spm_import $gnunet_namespace gstreamer
spm_import $gnunet_namespace gtk
spm_import $gnunet_namespace gtksourceview
spm_import $gnunet_namespace gtkwebkit

mkdir -p "$pkg_dir/.cache/spm"

jina "$pkg_dir"

echo '#!/usr/bin/env sh
"$(dirname "$(realpath "$0")")/../codev"
' > "$pkg_dir/.cache/spm/$ARCH/exec/codev"
chmod +x "$pkg_dir/.cache/spm/$ARCH/exec/codev"

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
