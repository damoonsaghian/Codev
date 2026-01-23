#!/usr/bin/env sh

# implement "spm" by wrapping apk commands

# update of /usr will be atomic
# the fact that alpine keeps info about installed packages in /usr/lib/apk/db (and not in /var), helps a lot

essential_packages="^alpine-base$
^eudev$
^eudev-netifnames$
^earlyoom$
^acpid$
^zzz$
^bluez$
^networkmanager-cli$
^wireless-regdb$
^mobile-broadband-provider-info$
^ppp-pppoe$
^dnsmasq$
^chrony$
^dcron$
^fwupd$
^linux-stable$
^systemd-boot$
^mkinitfs$
^btrfs-progs$
^cryptsetup$
^tpm2-tools$
^amd-ucode$
^intel-ucode$
^.codev-shell$
^.codev$"

# build quickshell from source, then install it in /usr/local/
build_and_install_quickshell() {
	local usr_dir="$1"
	[ -z "$usr_dir" ] && usr_dir=/usr
	
	mkdir -p /var/cache/src/cli11
	cd /var/cache/src/cli11
	git clone https://github.com/CLIUtils/CLI11
	cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=$usr_dir/local \
		-D CLI11_BUILD_TESTS=OFF -D CLI11_BUILD_EXAMPLES=OFF
	cmake --build build && cmake --install build
	
	mkdir -p /var/cache/src/quickshell
	cd /var/cache/src/quickshell
	git clone https://git.outfoxxed.me/quickshell/quickshell
	cmake -G Ninja -B build -W no-dev -D CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D CMAKE_INSTALL_PREFIX=$usr_dir/local -D INSTALL_QML_PREFIX=lib/qt6/qml \
		-D CRASH_REPORTER=OFF -D X11=OFF -D SERVICE_POLKIT=OFF \
		-D SERVICE_PAM=OFF -D WAYLAND_SESSION_LOCK=OFF -D WAYLAND_TOPLEVEL_MANAGEMENT=OFF
	cmake --build build && cmake --install build
}

case "$1" in
update)
	# exit if there is no updates
	[ -z "$(apk list --upgradable)" ] && exit
	
	# keep last kernel modules
	# /usr/lib/modules btrfs subvol
	
	[ -d /usr-new ] || btrfs subvolume snapshot /usr /usr-new
	unshare --mount sh -c "mount --bind /usr-new /usr && apk upgrade" || exit 1
	[ -d /home ] && rmdir --ignore-fail-on-non-empty /usr-new/home
	
	[ ! -f /tmp/fwupdmgr-status ] &&
		fwupdmgr refresh -y >/dev/null 2>&1 &&
		fwupdmgr get-updates -y >/dev/null 2>&1 &&
		touch /tmp/fwupdmgr-status
	
	[ -f /usr-new/local/bin/quickshell ] &&
	if apk info quickshell >/dev/null 2>&1; then
		unshare --mount sh -c "mount --bind /usr-new /usr && apk add quickshell --virtual .quickshell"
		# remove quickshell and cli11 files from /usr-new/local/
		rm -r /usr-new/local/bin/qs /usr-new/local/bin/quickshell /usr-new/local/lib/qt6/qml/Quickshell \
			/usr-new/local/share/applications/org.quickshell.desktop \
			/usr-new/local/share/icons/hicolor/scalable/apps/org.quickshell.svg \
			/usr-new/local/share/licenses/quickshell \
			/usr-new/local/include/CLI /usr-new/local/share/cmake/CLI11 \
			/usr-new/local/share/pkgconfig/CLI11.pc \
			/usr-new/local/share/licenses/cli11
		rmdir --ignore-fail-on-non-empty /usr-new/local/lib/qt6 /usr-new/local/share/applications /usr-new/local/share/icons \
			/usr-new/local/share/cmake /usr-new/local/share/pkgconfig /usr-new/local/share/licenses
	else
		build_and_install_quickshell /usr-new
	fi
	
	#todo: update spm-alpine codev-util codev-shell codev (in /usr-new/local)
	
	sh /usr/local/share/codev-util/spm-bootup.sh
	mv /usr-new /usr
	rm /tmp/spm-status
	;;
install)
	shift
	package=
	packages=
	installed_packages=
	for package in $@; do
		if apk info --exists "$package" >/dev/null 2>&1; then
			apk add "$package"
		elif apk info "$package" >/dev/null 2>&1; then
			packages="$packages $package"
		fi
	done
	[ -z "$packages" ] && exit
	
	[ -d /usr-new ] || btrfs subvolume snapshot /usr /usr-new
	unshare --mount sh -c "mount --bind /usr-new /usr && apk add $packages" || exit 1
	[ -d /home ] && rmdir --ignore-fail-on-non-empty /usr-new/home
	mv /usr-new /usr
	;;
remove)
	shift
	packages="$(echo "$@" | sed -n "s/ /\n/pg" | grep -v "$essential_packages")"
	apk del $packages
	;;
list)
	shift
	if [ -z "$@" ]; then
		# list all explicitly installed, non'essential packages
		grep -v "$essential_packages" /etc/apk/world
	else
		apk list $@
	fi
	;;
srv) openrc -U ;;
mkinst)
	script_dir="$(dirname "$(readlink -f "$0")")"
	. "$script_dir"/mkinst.sh "$2"
	;;
quickshell) build_and_install_quickshell ;;
esac
