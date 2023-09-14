import gLib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'

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
const Files = gtk.Widget.extend({
	project_directory: undefined,
	view: new gtk.TreeView(),
	model: new gtk.TreeModel(),
	
	init() {
		const theme = gtk.icon_theme_get_default()
		this.file_icon = theme.load_icon(gtk.STOCK_FILE, 48, 0)
		this.dir_icon = theme.load_icon(gtk.STOCK_DIRECTORY, 48, 0)
		
		// when scroll changes, change the css class of undershoot
	},
	
	move_up() {},

	move_down() {},

	go_to_file() {},

	find_file() {}
})
