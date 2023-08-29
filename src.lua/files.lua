local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")

--[[
https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
https://github.com/tchx84/Portfolio
http://zetcode.com/gui/pygtk/advancedwidgets/
https://github.com/MeanEYE/Sunflower
https://gitlab.xfce.org/apps/catfish/
https://gitlab.gnome.org/aviwad/organizer
https://github.com/donadigo/elementary-ide

archives: create a temp dir, and mount the archive there
.iso file: ask if user wants to view the content, if not, ask for a device to write it into
then unmount it if mounted, and if sucessful, do:
; sudo dd if=isofile of=devicename
]]

local Files = Gtk.Widget:extend(function(self, project_directory)
	self.view = Gtk.TreeView()
	self.model = Gtk.
	local theme = gtk.icon_theme_get_default()
	self.file_icon = theme.load_icon(Gtk.STOCK_FILE, 48, 0)
	self.dir_icon = theme.load_icon(Gtk.STOCK_DIRECTORY, 48, 0)
	self.project_directory = project_directory
end)

-- directory monitor
	
function Files:move_up()
end
	
function Files:move_down()
end
	
function Files:go_to_file()
end
	
function Files:find_file()
end

return Files
