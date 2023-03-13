from gi.repository import GLib, Gio, Gdk, Gtk

# https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
# https://github.com/tchx84/Portfolio
# http://zetcode.com/gui/pygtk/advancedwidgets/
# https://github.com/MeanEYE/Sunflower
# https://gitlab.xfce.org/apps/catfish/
# https://gitlab.gnome.org/aviwad/organizer
# https://github.com/donadigo/elementary-ide

# libarchive
# .iso file: ask if you want to extract it, if not ask for a device to write it into, then:
# ; sd flash devicename isofile

class Files:
	view
	model
	file_icon
	dir_icon
	
	__init_(project_dir):
		this.view = Gtk.TreeView()
		this.model = Gtk.;
		
		# directory monitor
	
	theme = gtk.icon_theme_get_default()
	this.file_icon = theme.load_icon(Gtk.STOCK_FILE, 48, 0)
	
	this.dir_icon = theme.load_icon(Gtk.STOCK_DIRECTORY, 48, 0)
	
	move_up():
	
	move_down():
	
	go_to_file():
	
	find_file():
