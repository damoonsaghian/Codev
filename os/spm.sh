#!/usr/bin/env -S pkexec /bin/bash

# simple package manager
# manages two kinds of packages
# , debian packages
# , SPM packages, which are simply source code directories, containing a file named "install.sh"
# SPM packages do not need dependency tracking
# managing dependencies is the job of language level package managers

# if $2 is an absolute path (start with "/"), meta_package=spm--path-hash
# /var/spm/hash-path-map-file
# after each update and remove, check all, if the path does not exist, remove package

meta_package=spm-"$PKEXEC_UID"--"$2"

if [ "$PKEXEC_UID" = 0 ]; then
	spm_path=/var/spm
	bin_path=/usr/local/bin
else
	spm_path="/home/$(id -n "$PKEXEC_UID")/.local/state/spm"
	bin_path="/home/$(id -n "$PKEXEC_UID")/.local/bin"
fi

download() {
	url="$1"
	protocol=
	
	if [ "$protocol" = git ] && ! command -v git 1>/dev/null; then
		spm add git
	end
	
	# run gnunet/git as spm
	# pkexec --user spm ...
}

# uninstall
project_path_hash="$(echo -n "$project_dir" | md5sum | cut -d ' ' -f1)"
spm remove jina-$project_path_hash 2>/dev/null

if [ "$1" = add ]; then
	# if $3 starts with gnunet:// or git://:
	# , downloads to (or updates) /var/spm/url_hash/
	# , if a public key is given as $4; use it to check the signature (in ".data/sig")
	# , runs install.sh script (as spm user)
	#	pkexec --user spm sh $spm_path/url-hash/install.sh
	#	read lines of the output, which start with "required package: "
	#	remove "required package: " from the line, replace spaces with comma, merge lines
	#	spm add $app_name $packages_list_comma_separated
	# , adds the package-url to $spm_path/url-list
	# , create a symlink from 0 to $bin_path/$app_name
	# exit
	#
	# entries in url-list are separated with an empty line, and they contain:
	# , app's name, which must be unique
	# , app's URL
	# , an optional public key (if present, will be used to check the signature of the downloaded files)
	
	packages="$3"
	
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
	mkdir -p "/tmp/spm/$meta_package/DEBIAN"
	cat <<-__EOF2__ > "/tmp/spm/$meta_package/DEBIAN/control"
	Package: $meta_package
	Version: $version
	Architecture: all
	Depends: $packages
	__EOF2__
	dpkg --build /tmp/spm/"$meta_package" /tmp/spm/ &>/dev/null
	
	apt-get update
	apt-get install /tmp/spm/"$meta_package"_"$version"_all.deb
elif [ "$1" == remove ]; then
	# first check if there is any spm package with this name, if yes:
	# , remove bin symlink, app folder, and app url from url-list
	# , spm remove $app_name
	# try to remove app as the owner of the path
	# if not:
	SUDO_FORCE_REMOVE=yes apt-get purge -- "$meta_package"
elif [ "$1" == sync ]; then
	apt-get update
	exit
elif [ "$1" == update ]; then
	# read url lines in $spm_path/url-list
	# download
	# if third line exists, it's a public key; use it to check the signature (in ".data/sig")
	# run install.sh in each one
	# check in each update, if the number of hard links to files in .cache/spm/app is 2, clean that package
	# number_of_links=$(stat -c %h filename)
	
	apt-get update
	apt-get dist-upgrade
	upm_apps
elif [ "$1" == autoupdate ]; then
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
