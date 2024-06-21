local lgi = require'lgi'
-- work around for Gtk4:
if require'lgi.version' <= '0.9.2' then
	local lgi_namespace = require'lgi.namespace'
	local lgi_namespace_require
	lgi_namespace_require = function(name, version)
		local core = require'lgi.core'
		local ns_info = assert(core.gi.require(name, version))
		local ns = rawget(core.repo, name)
		if not ns then
			ns = setmetatable(
				{ _name = name, _version = ns_info.version, _dependencies = ns_info.dependencies },
				lgi_namespace.mt
			)
			core.repo[name] = ns
			for name, version in pairs(ns._dependencies or {}) do
				lgi_namespace_require(name, version)
			end
			if ns._name ~= "Gtk" and ns._name ~= "Gdk" then
				local override_name = 'lgi.override.' .. ns._name
				local ok, msg = pcall(require, override_name)
				if not ok then
					if not msg:find("module '" .. override_name .. "' not found:", 1, true) then
						package.loaded[override_name] = nil
						require(override_name)
					end
				end
				if ok and type(msg) == "string" then error(msg) end
			end
		end
		return ns
	end
	lgi.require = lgi_namespace_require
	lgi.Gtk.disable_setlocale()
	lgi.Gtk.init()
end

glib = lgi.require 'GLib'
gio = lgi.require 'Gio'
gdk = lgi.require('Gdk', '4.0')
gtk = lgi.require('Gtk', '4.0')

--[[
http://lua-users.org/wiki/SimpleLuaClasses
https://github.com/jonstoler/class.lua
https://www.lua.org/pil/16.1.html
https://www.lua.org/pil/16.2.html
https://www.lua.org/pil/16.3.html

Object._property.extend = { extend = function(self, ...)
	local prototype = {}
	setmetatable(prototype, self)
	self.__index = self
	self.__call = function()
		local instance = self()
		setmetatable(instance, prototype)
		init(...)
		return instance
	end
	return prototype
end }
lgi.GObject.extend = Object.extend
]]

lgi.GObject.class_counter = 0
lgi.GObject.ClassPackage = lgi.package('ClassPackage')
lgi.GObject.extend = function(self, init, ...)
	local fields
	local interfaces = arg
	-- make a constructor from parent constructor (if any) and "init"
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
