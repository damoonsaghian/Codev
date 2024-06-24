# for implementing a prototype of Codev, it seems that the best tool at hand is PyGObject
# Python provides a simple consistent scripting API for almost anything
# https://docs.python.org/3/tutorial/
# https://docs.python.org/3/reference/index.html#reference-index
# https://docs.python.org/3/library/index.html	
# https://pygobject.gnome.org/guide/api/signals.html
# https://github.com/yucefsourani/python-gtk4-examples/tree/main/listbox_searchbar
# https://github.com/yucefsourani/python-gtk4-examples/tree/main/stack_flowbox_css_provider
# https://github.com/GNOME/pygobject/blob/master/examples/demo/demos/flowbox.py
# https://github.com/GNOME/pygobject/tree/master/examples/demo/demos/TreeView
# https://github.com/GNOME/pygobject/blob/master/examples/demo/demos/IconView/iconviewbasics.py
# https://github.com/GNOME/pygobject/blob/master/examples/demo/demos/IconView/iconviewedit.py
# https://github.com/GNOME/pygobject/blob/master/examples/demo/demos/Entry/search_entry.py
# https://lazka.github.io/pgi-docs/

import subprocess

import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gio, Gdk, Gtk

from overview import Overview

class MyApp(Gtk.Application):
	def do_activate(self):
		window = self.get_windows()[0]
		if not window:
			project_views = Gtk.Stack()
			
			overview = Overview(project_views)
			
			root_view = Gtk.Overlay()
			root_view.add(project_views)
			root_view.add_overlay(overview)
			# keybinding to show the overview;
			
			window = Gtk.ApplicationWindow(application=app, maximized=True, titlebar=None)
			window.set_child(root_view)
			
			# when window is unfocused, make it insensitive
		
			# when window is focused, make it sensitive again, then:
			# swaymsg "[workspace=__focused__ floating] focus" && {
			# 	swaymsg "[workspace=codev floating] move scratchpad; [app_id=swapps] move scratchpad;
			# 		[app_id=codev] move workspace codev; workspace codev; [app_id=codev] focus"
			# }
		
		window.present()

MyApp(application_id='codev').run(None)
