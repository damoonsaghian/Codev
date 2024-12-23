# for implementing a prototype of Codev, it seems that the best tool at hand is PyGObject
# Python provides a simple consistent scripting API for almost anything
# https://github.com/satwikkansal/wtfpython
# https://docs.gtk.org/gtk4/migrating-4to5.html

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
