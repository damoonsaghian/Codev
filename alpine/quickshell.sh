apk_new add git clang cmake pkgconf spirv-tools qt6-qtshadertools-dev wayland-protocols \
	jemalloc-dev qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtsvg-dev qt6-qtwayland-dev \
	wayland-dev mesa-dev libdrm-dev pipewire-dev \
	--virtual quickshell-git

apk_new add cli11 || {
	chroot "$new_root"
	mkdir -p /usr/local/src/cli11
	cd /usr/local/src/cli11
	# https://github.com/CLIUtils/CLI11
	cmake --install build
	exit
}

chroot "$new_root"

mkdir -p /usr/local/src/quickshell
cd /usr/local/src/quickshell
# https://git.outfoxxed.me/quickshell/quickshell

cmake -G Ninja -B build -W no-dev -D CMAKE_BUILD_TYPE=RelWithDebInfo -D CRASH_REPORTER=OFF -D X11=OFF -D SERVICE_POLKIT=OFF \
	-D SERVICE_PAM=OFF -D WAYLAND_SESSION_LOCK=OFF -D WAYLAND_TOPLEVEL_MANAGEMENT=OFF
cmake --build build
cmake --install build

exit
