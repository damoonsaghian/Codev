import subprocess

import 'gi'
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("GtkSource", "5.0")
gi.require_version("Webkit2", "5.0")
gi.require_version("Gst", "1.0")

from gi.repository import GLib, Gio, Gdk, Gtk

from overview import Overview

# https://pygobject.readthedocs.io/en/latest/
# https://github.com/GNOME/pygobject/tree/master/examples/demo/demos
# https://lazka.github.io/pgi-docs/main.html
# https://www.gtk.org/docs/apis/
# https://developer.gnome.org/documentation/

# slightly dim unfocused panels
# when moving or when "action" is pressed, create a flash which shows the location of the cursor

# backup: two'way diff

# new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

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
