import GLib from 'gi://GLib'
import Gio from 'gi://Gio'
import Gdk from 'gi://Gdk?version=4.0'
import Gtk from 'gi://Gtk?version=4.0'

/*
https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
https://github.com/tchx84/Portfolio
http://zetcode.com/gui/pygtk/advancedwidgets/
https://github.com/MeanEYE/Sunflower
https://gitlab.xfce.org/apps/catfish/
https://gitlab.gnome.org/aviwad/organizer

archives:
	bsdtar -xf <file-path>
.iso file: ask if user wants to extract it, if not, ask for a device to write it into, then:
; sudo dd if=isofile of=devicename
*/

export
const Files = Gtk.Widget.extend(function(project_directory) {
	this.view = new Gtk.TreeView()
	this.model = new Gtk.TreeModel()
	const theme = Gtk.icon_theme_get_default()
	this.file_icon = theme.load_icon(Gtk.STOCK_FILE, 48, 0)
	this.dir_icon = theme.load_icon(Gtk.STOCK_DIRECTORY, 48, 0)
	this.project_directory = project_directory
})

Files.prototype.move_up = function() {}

Files.prototype.move_down = function() {}

Files.prototype.go_to_file = function() {}

Files.prototype.find_file = function() {}
