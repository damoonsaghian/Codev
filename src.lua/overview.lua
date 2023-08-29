local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local Gdk = lgi.require('Gdk', '4.0')
local Gtk = lgi.require("Gtk", "4.0")

local Project = require 'project'

--[[
# left panel
#
# attached devices:
# https://docs.gtk.org/gio/class.VolumeMonitor.html
#
# ask the user if she wants to format the device, if:
# , it's not formated
# , it's a non'system device whose format is not vfat/exfat
# , it's a system device whose format is not btrfs
# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-property-org-freedesktop-UDisks2-Block.HintSystem
# http://storaged.org/doc/udisks2-api/latest/index.html
# https://lazka.github.io/pgi-docs/#Gio-2.0/classes/DBusConnection.html
# https://gjs.guide/guides/gio/dbus.html#direct-calls
# https://gjs.guide/guides/glib/gvariant.html#basic-usage
#
# to format it get the volume identifier
# https://docs.gtk.org/gio/iface.Volume.html
# use udisks to format non'system devices with vfat or exfat (if wants files bigger than 4GB)
# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
# type: fat
# mkfs-args: -F, 32, -I (to override partitions)
# for system devices:
# ; sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"
#
# projects on VFAT/exFAT formated devices will be opened as read'only
# when you try to edit them, you will be asked to copy them on to a BTRFS formated device
#
# mount it (if it's not)
# https://docs.gtk.org/gio/method.Volume.mount.html
]]

local ProjectsList = Gtk.Widget:extend(function(self, projects_dir_path)
	self.project_dir = Gio.File.new_for_path(project_dir_path)
	self.project_dir.enumerate_children(
		"", Gio.FileQueryInfoFlags.NONE, null,
		function(file_enumerator, result) end
	)
end)

ProjectsList.move_up = function(self)
end
	
ProjectsList.move_down = function(self)
end

ProjectsList.activate_project = function(self)
end


local Overview = Gtk.Widget:extend(function()
	container
	
	constructor(projects):
		this.projects_dirs = []
		# when a disk is mounted, add its "projects" directory to the list
		
		this.container = Gtk.Stack()
		
		this.container.set_halign(Gtk.Align.CENTER)
		this.container.set_valign(Gtk.Align.CENTER)
end)

Overview.activate_project = function(self, project_dir)
	-- if project_uri is in project_views, bring it up
	-- otherwise create a new Project
end
	
Overview.on_project_activated = function(self, callback)
	-- hide overview when a project is activated;
	
	callback(self.selected_project_dir)
end

return Overview
