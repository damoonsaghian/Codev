from gi.repository import GLib, Gio, Gdk, Gtk, WebKit2

# https://www.archlinux.org/packages/community/any/eolie/
# https://github.com/liske/barkery
# https://github.com/sonnyp/Tangram

# a userscript that shows the input language, and lets us change it

# if a page contains non'latin characters:
# , if no web fonts are provided, ask the user whether to install the relevent Noto font
# , activate the relevant keyboard layout
# , show keyboard layout indicator near cursor
# , provide a keybinding to switch between keyboard layouts

# if page contains emoji charactors add twemoji web font
# https://github.com/twitter/twemoji

class Web:
  __init__():
    view = Webkit2.WebView()
    view.load_uri("http://www.google.com/")
