from gi.repository import GLib, Gio, Gdk, Gtk, WebKit2

# https://www.archlinux.org/packages/community/any/eolie/
# https://github.com/sonnyp/Tangram

# a userscript that shows the input language, and lets us change it

class Web:
  __init__():
    view = Webkit2.WebView()
    view.load_uri("http://www.google.com/")
