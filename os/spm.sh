#!/usr/bin/env -S pkexec /bin/bash

# simple package manager
# manages two kinds of packages
# , debian packages
# , SPM packages, which are simply source code directories, containing a file named "install.sh"
# SPM packages do not need dependency tracking
# managing dependencies is the job of language level package managers

# this just adds the package-url to $HOME/.local/share/spm/url-list and runs install.sh script
# there must be an empty line between URL lines
# after each URL line, there can be a public key, which will be used to check the signature of the downloaded files

mode="$1"
meta_package=spm-"$PKEXEC_UID"--"$2"
packages="$3"

if [ "$PKEXEC_UID" = 0 ]; then
	install_path=/usr/local/
else
	install_path="/home/$(id -n $PKEXEC_UID)/.local/"
fi

download_external() {
	url="$1"
	protocol=
	
	if [ "$protocol" = git ] && ! command -v git 1>/dev/null; then
		spm add git
	end
}

add_external() {
	# add the url to $install_path/apps/url-list
	
	if [ "$protocol" = git ] && ! command -v git 1>/dev/null; then
		spm add git
	end
	
	# download to /var/spm/url_hash/ (run gnunet/git as spm)
	# run install.sh as spm user
	# pkexec --user spm sh /var/spm/url-hash/install.sh
	
	# "$install_path"/{app,bin,share}
	
	# $install_path/app/package-name/url
}

update_externals() {
	# read url lines in $install_path/apps/url-list
	
	# download it to "/var/spm/url_hash/"
	
	# if next line is not empty, it's a public key; use it to check the signature (in ".data/sig")
	
	# run install.sh in each one
	
	# check in each update, if the number of hard links to files in .cache/spm/app is 2, clean that package
	# number_of_links=$(stat -c %h filename)
}

# uninstall
# /var/spm/packagename
# list of files in $install_path/app/package-name/shared-file-list
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
