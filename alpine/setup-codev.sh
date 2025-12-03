apk_new add mesa-dri-gallium mesa-va-gallium breeze breeze-icons font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	font-adobe-source-code-pro

apk_new add quickshell || {
	# build and install quickshell
	# update hook for quickshell (first try apk add quickshell, and if failed build from git)
}

apk_new add qt6-qtvirtualkeyboard qt6-qtsensors

# keymap (qtvirtualkeyboard)
# https://doc.qt.io/qt-6/qtvirtualkeyboard-deployment-guide.html#integration-method


# install codev-shell
# "$new_root"/usr/local/share/codev-shell
# update hook for codev-shell

# "$new_root"/usr/local/share/codev-util
# doas rules for sd.sh
# "$new_root"/usr/local/share/alpine

apk_new add gnunet aria2
# https://wiki.alpinelinux.org/wiki/GNUnet

apk_new add mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-documents mauikit-terminal \
	kio-extras kimageformats qt6-qtsvg \
	qt6-qtmultimedia ffmpeg-libavcodec qt6-qtwebengine \
	qt6-qtlocation qt6-qtremoteobjects qt6-qtspeech \
	qt6-qtcharts qt6-qtgraphs qt6-qtdatavis3d qt6-qtquick3d qt6-qt3d qt6-qtquicktimeline
# qt6-qtquick3dphysics qt6-qtlottie

# install codev
# "$new_root"/usr/local/share/codev
# .data/codev.svg

# update hook for files in codev codev-shell codev-util and alpine
