local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")

local Files = require 'files'
local Editor = require 'editor'
local Gallery = = require 'gallery'

-- floating layer to view web'pages, images and videos

-- if there is a saved session file for the project, restore it

-- backup: two'way diff

local Project = Gtk.Widget:extend(function()
	this.main_view = Gtk.Stack()
	
	this.overlay = Gtk.Stack()
	
	this.container = Gtk.Overlay()
	this.container.add(this.main_view)
	this.container.add_overlay(this.overlay)
	
	-- if there is a saved session file for the project, restore it
	-- if there is no view, open a view showing the project's files
end)

return Project
