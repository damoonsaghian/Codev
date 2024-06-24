import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gio, Gdk, Gtk

# https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
# https://github.com/tchx84/Portfolio
# http://zetcode.com/gui/pygtk/advancedwidgets/
# https://github.com/MeanEYE/Sunflower
# https://gitlab.xfce.org/apps/catfish/
# https://gitlab.gnome.org/aviwad/organizer

# https://github.com/donadigo/elementary-ide

# archives:
# bsdtar -xf <file-path>

# .iso file: ask if user wants to extract it, if not, ask for a device to write it into, then:
# ; sudo dd if=isofile of=devicename

class Files(Gtk.Listbox):
	def __init__(project_directory):
	
	def move_up():

	def move_down():

	def go_to_file():

	def find_file():
