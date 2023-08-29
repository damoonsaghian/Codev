local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")
local Gst = lgi.require("Gst", "1.0")

-- gtk4 mediafile

-- for gallery view: gtk::FlowBox, gtk::Scrollable
-- https://github.com/karlch/vimiv
-- https://gitlab.com/Strit/griffith
-- https://gitlab.gnome.org/GNOME/shotwell/tree/master/src
-- https://gitlab.gnome.org/GNOME/gnome-music
-- https://gitlab.gnome.org/World/lollypop/-/tree/master/lollypop
-- https://github.com/quodlibet/quodlibet/
-- https://gitlab.gnome.org/GNOME/pitivi/-/tree/master/pitivi
-- https://github.com/jliljebl/flowblade

-- subtitles and comments
-- https://github.com/otsaloma/gaupol/tree/master/gaupol

-- gdk-pixbuf-thumbnailer -s 128 %u %o

-- gtk_application_inhibit gtk_application_uninhibit

local Gallery = Gtk.Widget:extend(function()
	this.container = Gtk.ScrolledWindow()
	this.container.set_policy(Gtk.POLICY_AUTOMATIC, Gtk.POLICY_AUTOMATIC)
	
	theme = Gtk.iconThemeGetDefault()
	this.file_icon = theme.loadIcon(Gtk.STOCK_FILE, 48, 0)
	this.dir_icon = theme.loadIcon(Gtk.STOCK_DIRECTORY, 48, 0)
	
	this.store = Gtk.ListStore(str, Gtk.gdk.Pixbuf, bool)
	this.store.set_sort_column_id(0, Gtk.SORT_ASCENDING)
	this.store.clear()
	
	this.view = Gtk.IconView()
end)
	
Gallery.move_up = function(self)
end
	
Gallery.move_down = function(self)
end
	
Gallery.go_to_item = function(self)
end
	
Gallery.find = function(self)
end

return Gallery
