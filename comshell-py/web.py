from gi.repository import Gtk, Gdk, Gio, GLib, WebKit2

# https://www.archlinux.org/packages/community/any/eolie/
# https://github.com/sonnyp/Tangram

class Web:
  __init__():
    view = Webkit2.WebView()
    view.load_uri("http://www.google.com/")
