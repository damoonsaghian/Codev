import gLib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'
import gst from 'gi://Gst?version=1.0'

import Scroll from "scroll"

// gtk4 mediafile

// for gallery view: gtk::FlowBox, gtk::Scrollable
// https://github.com/karlch/vimiv
// https://gitlab.com/Strit/griffith
// https://gitlab.gnome.org/GNOME/shotwell/tree/master/src
// https://gitlab.gnome.org/World/vocalis
// https://gitlab.gnome.org/GNOME/gnome-music
// https://gitlab.gnome.org/World/lollypop/-/tree/master/lollypop
// https://github.com/quodlibet/quodlibet/
// https://gitlab.gnome.org/GNOME/pitivi/-/tree/master/pitivi
// https://github.com/jliljebl/flowblade

// subtitles and comments
// https://github.com/otsaloma/gaupol/tree/master/gaupol

// gdk-pixbuf-thumbnailer -s 128 %u %o

// gtk_application_inhibit gtk_application_uninhibit

const Gallery = Scroll.extend(function() {
	const theme = gtk.iconThemeGetDefault()
	this.file_icon = theme.loadIcon(gtk.STOCK_FILE, 48, 0)
	this.dir_icon = theme.loadIcon(gtk.STOCK_DIRECTORY, 48, 0)
	
	this.store = gtk.ListStore(str, gdk.Pixbuf, bool)
	this.store.set_sort_column_id(0, gtk.SORT_ASCENDING)
	this.store.clear()
	
	this.set_child(new gtk.IconView())
})
	
Gallery.prototype.move_up = function() {}

Gallery.prototype.move_down = function() {}

Gallery.prototype.go_to_item = function() {}

Gallery.prototype.find = function() {}

export default Gallery
