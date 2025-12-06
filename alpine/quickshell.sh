# build quickshell from source, then install it in /usr/local/

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
