apt-get -qq install iwd wireless-regdb bluez rfkill passwd fzy

cp /mnt/os/system /usr/local/bin/
chmod +x /usr/local/bin/system

systemctl enable iwd.service

echo '# allow rfkill for users in the netdev group
KERNEL=="rfkill", MODE="0664", GROUP="netdev"
' > /etc/udev/rules.d/80-rfkill.rules

echo; echo "setting timezone"
# guess the timezone, but let the user to confirm it
command -v wget > /dev/null 2>&1 || apt-get -qq install wget > /dev/null 2>&1 || true
geoip_tz="$(wget -q -O- 'http://ip-api.com/line/?fields=timezone')"
geoip_tz_continent="$(echo "$geoip_tz" | cut -d / -f1)"
geoip_tz_city="$(echo "$geoip_tz" | cut -d / -f2)"
tz_continent="$(ls -1 -d /usr/share/zoneinfo/*/ | cut -d / -f5 |
	fzy -p "select a continent: " -q "$geoip_tz_continent")"
tz_city="$(ls -1 /usr/share/zoneinfo/"$tz_continent"/* | cut -d / -f6 |
	fzy -p "select a city: " -q "$geoip_tz_city")"
ln -sf "/usr/share/zoneinfo/${tz_continent}/${tz_city}" /etc/localtime

echo -n 'polkit.addRule(function(action, subject) {
	if (
		action.id == "org.freedesktop.timedate1.set-timezone" &&
		subject.local && subject.active
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-timezone.rules

cat <<'__EOF__' > /usr/local/bin/ospkg-deb
#!/usr/bin/env -S pkexec /bin/bash
mode="$1"
meta_package=ospkg-"$PKEXEC_UID"--"$2"
packages="$3"

if [ "$1" = add ]; then
	version="$(dpkg-query -f='${Version}' -W "$meta_package" 2> /dev/null)"
	if [ -z "$version" ]; then
		# there is no installed package named $meta_package
		version=0
	else
		# there is an installed package named $meta_package
		
		# sort $packages
		packages="$(echo "$packages" | tr -d '[:blank:]' | tr , "\n" | sort -u | tr "\n" ,)"
		# trim commas at the begining and the end
		packages="${packages%,}"; packages="${packages#,}"
		
		# find dependencies of $meta_package, and sort them
		dependecies="$(dpkg-query -f='${Depends}' -W "$meta_package")"
		dependecies="$(echo "$dependecies" | tr -d '[:blank:]' | tr , "\n" | sort -u | tr "\n" ,)"
		dependecies="${dependecies%,}"; dependecies="${dependecies#,}"
		
		if [ "$packages" = "$dependencies" ]; then
			exit
		else
			version=$((version+1))
		fi
	fi
	
	# create the meta package
	mkdir -p /tmp/ospkg-deb/"$meta_package"/DEBIAN
	cat <<-__EOF2__ > /tmp/ospkg-deb/"$meta_package"/DEBIAN/control
	Package: $meta_package
	Version: $version
	Architecture: all
	Depends: $packages
	__EOF2__
	dpkg --build /tmp/ospkg-deb/"$meta_package" /tmp/ospkg-deb/ &>/dev/null
	
	apt-get update
	apt-get install /tmp/ospkg-deb/"$meta_package"_"$version"_all.deb
elif [ "$1" == remove ]; then
	SUDO_FORCE_REMOVE=yes apt-get purge -- "$meta_package"
elif [ "$1" == update ]; then
	apt-get update
elif [ "$1" == upgrade ]; then
	apt-get update
	apt-get dist-upgrade
fi

apt-get -qq --purge autoremove
apt-get -qq autoclean
__EOF__
chmod +x /usr/local/bin/ospkg-deb

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="org.local.pkexec.ospkg-deb">
		<description>ospkg-deb</description>
		<message>ospkg-deb</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/bash</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/ospkg-deb</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/org.local.pkexec.ospkg-deb.policy

# https://www.freedesktop.org/wiki/Software/systemd/inhibit/
cat <<'__EOF__' > /usr/local/share/automatic-update.sh
metered_connection() {
	local active_net_device="$(ip route show default | head -1 | sed -n "s/.* dev \([^\ ]*\) .*/\1/p")"
	local is_metered=false
	case "$active_net_device" in
		ww*) is_metered=true ;;
	esac
	# todo: DHCP option 43 ANDROID_METERED
	$is_metered
}
metered_connection && exit 0

apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get -qq -o Dpkg::Options::=--force-confnew dist-upgrade

apt-get -qq --purge autoremove
apt-get -qq autoclean
__EOF__

mkdir -p /usr/local/lib/systemd/system
echo -n '[Unit]
Description=automatic update
ConditionACPower=true
After=network-online.target
[Service]
Type=oneshot
ExecStartPre=-/usr/lib/apt/apt-helper wait-online
ExecStart=/bin/sh /usr/local/share/automatic-update.sh
KillMode=process
TimeoutStopSec=900
Nice=19
' > /usr/local/lib/systemd/system/automatic-update.service
echo -n '[Unit]
Description=automatic update
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/system/automatic-update.timer
systemctl enable automatic-update.timer

cat <<-'__EOF__' > "/usr/local/share/apps.sh"
# read url lines in "$HOME/.local/apps/url-list"
if [ "$protocol" = gnunet ]; then
	ospkg add apps-gnunet gnunet
elif [ "$protocol" = git ]; then
	ospkg add apps-git git
end
# download it to "$HOME/.cache/packages/url_hash/"
# if there is no update, just exit
# if next line is not empty, it's a public key; use it to check the signature (in ".data/sig")
# run install.sh in each one
__EOF__

mkdir -p /usr/local/lib/systemd/user
echo -n '[Unit]
Description=apps
ConditionACPower=true
[Service]
Type=oneshot
ExecStart=/bin/sh /usr/local/share/apps.sh
KillMode=process
TimeoutStopSec=900
Nice=19
' > /usr/local/lib/systemd/user/apps.service
echo -n '[Unit]
Description=apps
[Timer]
OnBootSec=5min
OnUnitInactiveSec=24h
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
' > /usr/local/lib/systemd/user/apps.timer
echo -n '[Unit]
Description=apps
[Path]
PathChanged=%h/.local/apps/url-list
Unit=user-apps.service
' > /usr/local/lib/systemd/user/apps.path
systemctl --global enable apps.timer
systemctl --global enable apps.path
