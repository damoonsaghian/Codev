import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gio, Gdk, Gtk

# floating layer to view web'pages, images and videos

# if there is a saved session file for the project, restore it

class Project(Gtk.Overlay):
	def __init__(dir_path):
		self.dir_path = dir_path
		
		self.main_view = Gtk.Stack()
		
		# create a File and send it a weak ref of this Project
		self.floating_layer = Gtk.Stack()
		
		self.add(self.main_view)
		self.add_overlay(self.floating_layer)
