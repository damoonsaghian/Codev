#!/usr/bin/env -S pkexec /bin/bash

mode="$1"
meta_package=spm-"$PKEXEC_UID"--"$2"
packages="$3"

# simple package manager
# an SPM package is simply a source code directory, containing a file named "install.sh"
# spm add <package-url> ...
# this just adds the package-url to $HOME/.local/share/spm/url-list and runs install.sh script
# there must be an empty line between URL lines
# after each URL line, there can be a public key, which will be used to check the signature of the downloaded files

add_external() {
	if [ "$protocol" = gnunet ]; then
		spm add gnunet
	elif [ "$protocol" = git ]; then
		spm add git
	end
	# download it to "$HOME/.cache/packages/url_hash/"
	
	# if $PKEXEC_UID = 0 add the url to /var/local/spm/url_list
	# download to /var/local/spm/url_hash/
	# run install.sh as spm user
}

update_externals() {
	# if $PKEXEC_UID = 0 read url lines in /var/local/spm/url_list
	# otherwise, read url lines in "/home/$(id -n $PKEXEC_UID)/.local/spm/url-list"
	
	# download it to "$HOME/.cache/packages/url_hash/"
	# if there is no update, just exit
	# if next line is not empty, it's a public key; use it to check the signature (in ".data/sig")
	# run install.sh in each one
	
}

# uninstall
# /usr/local/share/spm/package-url-hash
# list of files in ~/.local/spm/packagename (if root: /var/local/)
project_path_hash="$(echo -n "$project_dir" | md5sum | cut -d ' ' -f1)"
spm remove jina-$project_path_hash 2>/dev/null

if [ "$1" = add ]; then
	# grab "--deb=" args, and if there isn't any:
	# echo "no packages are provided for this system"
	
	[ -z "$packages" ] && packages="$meta_package"
	
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
