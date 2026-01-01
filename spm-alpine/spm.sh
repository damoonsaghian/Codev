#!/usr/bin/env sh

# implement "spm" by wrapping apk commands

# build quickshell from source, then install it in /usr/local/
build_and_install_quickshell() {
	mkdir -p /var/cache/src/cli11
	cd /var/cache/src/cli11
	git clone https://github.com/CLIUtils/CLI11
	cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=$new_usr/local \
		-D CLI11_BUILD_TESTS=OFF -D CLI11_BUILD_EXAMPLES=OFF
	cmake --build build && cmake --install build
	
	mkdir -p /var/cache/src/quickshell
	cd /var/cache/src/quickshell
	git clone https://git.outfoxxed.me/quickshell/quickshell
	cmake -G Ninja -B build -W no-dev -D CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D CMAKE_INSTALL_PREFIX=$new_usr/local -D INSTALL_QML_PREFIX=lib/qt6/qml \
		-D CRASH_REPORTER=OFF -D X11=OFF -D SERVICE_POLKIT=OFF \
		-D SERVICE_PAM=OFF -D WAYLAND_SESSION_LOCK=OFF -D WAYLAND_TOPLEVEL_MANAGEMENT=OFF
	cmake --build build && cmake --install build
}

prepare_usr() {
	local current_usr=
	if [ $(stat -c %i /usr) = $(stat -c %i /usr0) ]; then
		current_usr="/usr0"
		new_usr="/usr1"
	elif [ $(stat -c %i /usr) = $(stat -c %i /usr1) ]; then
		current_usr="/usr1"
		new_usr="/usr0"
	fi
	rm -rf "$new_usr"
	btrfs snapshot "$current_usr" "$new_usr"
}

boot_entry() {
	# boot entry: usrflags=subvol=$new_usr
	# if a new boot entry is available (due to kernel, systemd-boot, or ucode being updated),
	# 	do the above there, then make that entry default
	
	echo reboot > /tmp/spm-status
}

switch_usr() {
	echo "new packages will be available on the next reboot"
	echo "do you want them on currently running system? (y/N)"
	read -r ans
	[ "$ans" = y ] || [ "$ans" = yes ] && mount --bind "$new_usr" /usr && rm /tmp/spm-status
}

case "$1" in
update)
	prepare_usr
	unshare --mount sh -c "mount --bind $new_usr /usr && apk upgrade" || {
		echo error > /tmp/spm-status
		exit 1
	}
	
	[ -f $new_usr/local/bin/quickshell ] || if apk info quickshell &>/dev/null; then
		unshare --mount sh -c "mount --bind $new_usr /usr && apk add quickshell --virtual .quickshell"
		# remove quickshell and cli11 files from $new_usr/local/
		rm -r $new_usr/local/bin/qs $new_usr/local/bin/quickshell $new_usr/local/lib/qt6/qml/Quickshell \
			$new_usr/local/share/applications/org.quickshell.desktop \
			$new_usr/local/share/icons/hicolor/scalable/apps/org.quickshell.svg \
			$new_usr/local/share/licenses/quickshell \
			$new_usr/local/include/CLI $new_usr/local/share/cmake/CLI11 \
			$new_usr/local/share/pkgconfig/CLI11.pc \
			$new_usr/local/share/licenses/cli11
		rmdir --ignore-fail-on-non-empty $new_usr/local/lib/qt6 $new_usr/local/share/applications $new_usr/local/share/icons \
			$new_usr/local/share/cmake $new_usr/local/share/pkgconfig $new_usr/local/share/licenses
			
	else
		build_and_install_quickshell
	fi
	
	[ -d /home ] && rmdir --ignore-fail-on-non-empty /home
	
	#todo: update spm-alpine codev-util codev-shell codev (in $new_usr/local)
	
	boot_entry
	[ "$2" = auto ] && switch_usr
	;;
install)
	prepare_usr
	shift
	unshare --mount sh -c "mount --bind $new_usr /usr && apk add $@" || exit 1
	boot_entry
	switch_usr
	;;
remove) shift; apk del $@ ;;
list) shift; apk list $@ ;;
srv) openrc -U ;;
mkinst)
	script_dir="$(dirname "$(realpath "$0")")"
	. "$script_dir"/mkinst.sh
	;;
quickshell)
	new_root=
	build_and_install_quickshell
	;;
esac
