from gi.repository import GLib, Gio, Gdk, Gtk

from files import Files
from editor import Editor
from gallery import Gallery

# floating layer to view web'pages, images and videos

# if there is a saved session file for the project, restore it

# backup: two'way diff

class Project:
	main_view
	overlay
	container

	__init__():
		this.main_view = Gtk.Stack()
		
		this.overlay = Gtk.Stack()
		
		this.container = Gtk.Overlay()
		this.container.add(this.main_view)
		this.container.add_overlay(this.overlay)
		
		# if there is a saved session file for the project, restore it
		# if there is no view, open a view showing the project's files
