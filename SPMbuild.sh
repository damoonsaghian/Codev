pkg=codev

spm_build jina
spm_import jin-std
spm_import jin-gui
spm_import jin-codec
spm_import gnunet
spm_import ssh
spm_import sd

"$PKGjina"/exec/jina "$pkg_dir"

spm_xcript inst/app codev

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
