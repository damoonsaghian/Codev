#!/usr/bin/env sh

# implement "spm" by wrapping apk commands

# build quickshell from source, then install it in /usr/local/
build_and_install_quickshell() {
	mkdir -p /usr/local/src/cli11
	cd /usr/local/src/cli11
	git clone https://github.com/CLIUtils/CLI11
	cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr/local \
		-D CLI11_BUILD_TESTS=OFF -D CLI11_BUILD_EXAMPLES=OFF
	cmake --build build && cmake --install build
	
	mkdir -p /usr/local/src/quickshell
	cd /usr/local/src/quickshell
	git clone https://git.outfoxxed.me/quickshell/quickshell
	cmake -G Ninja -B build -W no-dev -D CMAKE_BUILD_TYPE=RelWithDebInfo \
		-D CMAKE_INSTALL_PREFIX=/usr/local -D INSTALL_QML_PREFIX=lib/qt6/qml \
		-D CRASH_REPORTER=OFF -D X11=OFF -D SERVICE_POLKIT=OFF \
		-D SERVICE_PAM=OFF -D WAYLAND_SESSION_LOCK=OFF -D WAYLAND_TOPLEVEL_MANAGEMENT=OFF
	cmake --build build && cmake --install build
}

prepare_usr() {
	# check which subvolume is mounted on /usr, usr0 or usr1; let's say it's usr0
	current_usr=/usr0
	new_usr=/usr1
	rm -f "$new_usr"
	# create a snapshot of "$current_usr" to "$new_usr"
	new_root="$(mktemp -d)"
	# mount rbind root into it
	# umount <tmp-dir>/usr
	# mount <tmp-dir>/usr1 <tmp-dir>/usr
}

switch_usr() {
	echo "new packages will be available on the next reboot"
	echo "do you want them on currently running system? (y/N)"
	read -r ans
	[ "$ans" = y ] || [ "$ans" = yes ] && mount "$new_usr" /usr
}

case "$1" in
update)
	prepare_usr
	apk upgrade
	
	[ -f /usr/local/bin/quickshell ] || if apk info quickshell &>/dev/null; then
		apk add quickshell --virtual .quickshell
		# remove quickshell and cli11 files from /usr/local/
	else
		build_and_install_quickshell
	fi
	
	[ -d /home ] && rmdir --ignore-fail-on-non-empty /home
	
	# spm-alpine codev-util codev-shell codev
	
	# create update notification file
	
	[ "$2" = auto ] && switch_usr
	;;
install)
	prepare_usr
	shift; apk add $@
	
	# if there are services, ask user whether to activate it or not
	
	# create update notification file
	
	switch_usr
	;;
remove) shift; apk del $@ ;;
list) shift; apk list $@ ;;
srv) openrc -U ;;
mkinst)
	script_dir="$(dirname "$(realpath "$0")")"
	. "$script_dir"/mkinst.sh
	;;
quickshell) build_and_install_quickshell ;;
esac
