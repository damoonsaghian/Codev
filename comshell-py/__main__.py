import subprocess

import gi
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("GtkSource", "5.0")
gi.require_version("Webkit2", "5.0")
gi.require_version("Gst", "1.0")

from gi.repository import GLib, Gio, Gdk, Gtk

from overview import Overview

# https://pygobject.readthedocs.io/en/latest/
# https://lazka.github.io/pgi-docs/main.html
# https://www.gtk.org/docs/apis/

# create a project group -> ask user for the disk

# there are two key configurations:
#   one for comshell keyboards (the one shown above), and one for conventional keyboards
# Comshell keyboards have product name "Comshell"
# so Comshell can detect Comshell keyboards (using eg "xinput"),
#   and selects the right configuration automatically

# floating layer to view web'pages, images and videos

# bsdtar (libarchive-tools) (zip, iso, ...)
# bsdtar -xf file

# https://github.com/kupferlauncher/kupfer
# https://github.com/muflone/gnome-appfolders-manager

# screenshot ...
# sleep 3; grim .data/...
# show countdown in status'bar
# insert the image path in buffer

# notifications:
# create a layer in the bottom'left corner, to print notifications, using:
#   python3-cffi + wlroots (layer-shell) + python3-cairocffi
# https://cffi.readthedocs.io/en/latest/
# https://cairocffi.readthedocs.io/en/stable/
# at startup scan email boxes of projects, and show notifications
# during the runtime add/remove notifications

Gtk.init(null)

projects = Gtk.Stack()

overview = Overview(projects)

main_view = Gtk.Overlay()
main_view.add(projects)
main_view.add_overlay(overview.container)
# keybinding to show the overview;

win = new Gtk.Window()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", gtk.main_quit)
win.show_all()
win.maximize()
gtk.main()
