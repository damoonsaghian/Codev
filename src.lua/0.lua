local lgi = require 'lgi'

lgi.GObject.class_counter = 0
lgi.GObject.ClassPackage = lgi.package('ClassPackage')
lgi.GObject.extend = function(self, init, ...)
	local fields
	local interfaces = arg
	-- make a constructor from parent constructor and "init"
	self.__call = function(...)
		local object
		init(...)
		return object
	end
	lgi.GObject.class_counter = lgi.GObject.class_counter + 1
	lgi.GObject.ClassPackage:class('class' .. lgi.GObject.class_counter, self, interfaces)
	-- set __newindex to automatically add fields to properties
end
lgi.GObject.TypeInstance.extend = lgi.GObject.extend

local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")

local Overview = require 'overview'

--[[
for implementing a prototype of Codev, it seems that the best tool at hand is Lua LGI

https://github.com/hengestone/lua-languages
https://github.com/thenumbernine/symmath-lua
https://www.gtk.org/docs/apis/
https://developer.gnome.org/documentation/

slightly dim unfocused panels

new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

use colored lines on top and bottom of scrollables to show the amount of content above and below
local style_provider = Gtk.CssProvider()
local css_path =
style_provider.load_from_file(Gio.File.new_for_path(css_path))
Gtk.StyleContext.add_provider_for_screen(
	Gdk.Screen.get_default(),
	style_provider,
	Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

GNUnet: audio conversasion is already implemented
https://git.gnunet.org/gnunet.git/tree/src/conversation
https://git.gnunet.org/gnunet.git/tree/src/conversation/gnunet_gst.c
https://manpages.debian.org/unstable/gnunet/gnunet-conversation.1.en.html
figure out how to send/receive streams to/from gnunet
use gstreamer gio plugin to send/receive streams to/from gstreamer
use gstreamer pipewire plugin to access camera
	libaperture, libaravis
use gtk4 mediafile to put it on gui
]]

local projects = Gtk.Stack.new()

local overview = Overview.new(projects)

local main_view = Gtk.Overlay.new()
main_view.add(projects)
main_view.add_overlay(overview.container)
-- keybinding to show the overview;

local win = Gtk.Window.new()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", gtk.main_quit)
win.show_all()
win.maximize()
gtk.main()
