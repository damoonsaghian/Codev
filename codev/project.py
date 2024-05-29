# floating layer to view web'pages, images and videos

# if there is a saved session file for the project, restore it

# backup: two'way diff

class Project:
	def __init__(dir_path):
		self.dir_path = dir_path
		
		self.main_view = Gtk.Stack()
		
		# create a File and send it a weak ref of this Project
		self.floating_layer = Gtk.Stack()
		
		self.widget = Gtk.Overlay()
		self.widget.add(self.main_view)
		self.widget.add_overlay(self.floating_layer)
