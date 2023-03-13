from gi.repository import GLib, Gio, Gdk, Gtk, WebKit2

# https://www.archlinux.org/packages/community/any/eolie/
# https://github.com/liske/barkery
# https://github.com/sonnyp/Tangram

# non'English pages are managed using a userscript
# on non'English pages:
# , activate the relevant keyboard layout
# , show keyboard layout indicator near cursor
# , provide a keybinding to switch between keyboard layouts
# if a page contains non'latin characters, and web fonts are not provided, install the relevent Noto web font
# if page contains emoji charactors add twemoji web font
# https://github.com/twitter/twemoji

class Web:
	__init__():
		view = Webkit2.WebView()
		view.load_uri("http://www.google.com/")
