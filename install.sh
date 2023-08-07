command -v jina > /dev/null 2>&1 || apt-get install jina || {
	echo 'to build Codev, "jina" must be installed on the system'
	exit 1
}
apt-get install dosfstools exfatprogs btrfs-progs libarchive13 gnunet

project_dir="$(dirname "$0")"
jina build "$project_dir"
cp "$project_dir/.cache/jina/codev" /usr/local/bin/

mkdir -p /usr/local/share/applications
cat <<-__EOF__ > /usr/local/share/applications/codev.desktop
[Desktop Entry]
Type=Application
Name=Codev
Icon=codev
Exec=/usr/local/bin/codev
StartupNotify=true
__EOF__

cat <<-__EOF__ > /usr/local/share/icons/hicolor/scalable/apps/codev.svg
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

first_user="$(id -un 1000)"
usermod -aG gnunet "$first_user"
su -c "touch \"/home/$first_user/.config/gnunet.conf\"" "$first_user"
echo -n '[ats]
WLAN_QUOTA_IN = unlimited
WLAN_QUOTA_OUT = unlimited
WAN_QUOTA_IN = unlimited
WAN_QUOTA_OUT = unlimited
' >> "/home/$first_user/.config/gnunet.conf"
