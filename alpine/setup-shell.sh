apk_new add mesa-dri-gallium mesa-va-gallium font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	font-adobe-source-code-pro

apk add quickshell || {
	# build and install quickshell
}
# update hook for quickshell (if "apk add quickshell" fails)

# keymap (qtvirtualkeyboard)
# https://doc.qt.io/qt-6/qtvirtualkeyboard-deployment-guide.html#integration-method

# install codev-shell
# /usr/local/share/codev-shell
# /usr/local/share/codev-util
# /usr/local/share/alpine

# update hook for codev-shell
