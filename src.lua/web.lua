local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")
local Webkit = lgi.require("Webkit2", "5.0")

--[[
https://www.archlinux.org/packages/community/any/eolie/
https://github.com/liske/barkery
https://github.com/sonnyp/Tangram

non'English pages are managed using a userscript
on non'English pages:
, activate the relevant keyboard layout
, show keyboard layout indicator near cursor
, provide a keybinding to switch between keyboard layouts
if a page contains non'latin characters, and web fonts are not provided, install the relevant Noto web font
if page contains emoji charactors add twemoji web font
https://github.com/twitter/twemoji
]]

local Web = Gtk.Widget:extend(function()
	view = Webkit.WebView()
	view.load_uri("http://www.google.com/")
end)

return Web
