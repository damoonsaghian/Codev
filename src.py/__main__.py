# for implementing a prototype of Codev, it seems that the best tool at hand is PyGObject
# Python provides a simple consistent scripting API for almost anything

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

# new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

# use colored lines on top and bottom of scrollables to show the amount of content above and below
# css style in python-gobject:
#style_provider = Gtk.CssProvider()
#base_dir = os.path.abspath(os.path.dirname(__file__))
#css_path = os.path.join(base_dir, 'input_paste.css')
#style_provider.load_from_file(Gio.File.new_for_path(css_path))
#Gtk.StyleContext.add_provider_for_screen(
#	Gdk.Screen.get_default(),
#	style_provider,
#	Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
#)

# audio conversasion is already implemented
# https://git.gnunet.org/gnunet.git/tree/src/conversation
# https://git.gnunet.org/gnunet.git/tree/src/conversation/gnunet_gst.c
# https://manpages.debian.org/unstable/gnunet/gnunet-conversation.1.en.html
# figure out how to send/receive streams to/from gnunet
# use gstreamer gio plugin to send/receive streams to/from gstreamer
# use gstreamer pipewire plugin to access camera
# 	libaperture, libaravis
# use gtk4 mediafile to put it on gui

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
