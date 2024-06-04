#!/usr/bin/env -S pkexec /bin/bash

# unified package manager

mode="$1"
meta_package=upm-"$PKEXEC_UID"--"$2"
packages="$3"

upm_apps() {
	# UPM app is simply a source code directory, containing a file named "install.sh"
	# upm add <app-url> ...
	# there must be an empty line between URL lines
	# after each URL line, there can be a public key, which will be used to check the signature of the downloaded files
	
	home_dir="/home/$(id -un )"
	
	read url lines in "/usr/var/local/upm/$PKEXEC_UID/apps"
	if [ "$protocol" = gnunet ]; then
		upm add gnunet --deb=gnunet
	elif [ "$protocol" = git ]; then
		upm add git --deb=git
	end
	# download it to "$home_dir/.cache/packages/url_hash/"
	# if there is no update, just exit
	# if next line is not empty, it's a public key; use it to check the signature (in ".data/sig")
	# run install.sh in each one
}

if [ "$1" = add ]; then
	# grab "--deb=" args, and if there isn't any:
	# echo "no packages are provided for this system"
	
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
	upm_apps
elif [ "$1" == auto-upgrade ]; then
	# https://www.freedesktop.org/wiki/Software/systemd/inhibit/
	
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
fi

apt-get -qq --purge autoremove
apt-get -qq autoclean
