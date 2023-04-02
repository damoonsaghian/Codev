from gi.repository import GLib, Gio, Gdk, Gtk

from project import Project

# left panel
#
# attached devices:
# https://docs.gtk.org/gio/class.VolumeMonitor.html
#
# if a device is not formated, ask the user if she wants to format it
# to format it get the volume identifier
# https://docs.gtk.org/gio/iface.Volume.html
# use udisks to format it
# http://storaged.org/doc/udisks2-api/latest/index.html
# https://lazka.github.io/pgi-docs/#Gio-2.0/classes/DBusConnection.html
# https://gjs.guide/guides/gio/dbus.html#direct-calls
# https://gjs.guide/guides/glib/gvariant.html#basic-usage
# format types:
# , removable: vfat
# , removable containing files bigger than 4GB: exfat
# , internal: btrfs
#
# projects on VFAT/exFAT formated devices will be opened as read'only
# when you try to edit them, you will be asked to copy them on to a BTRFS formated device
#
# mount it (if it's not)
# https://docs.gtk.org/gio/method.Volume.mount.html
# the device will be mounted in ~/.local/sd-mount/$device_name
# to unmount:
# ; sd unmount $device_name
#
# if it's a system device use sudo to mount anf format it
# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-property-org-freedesktop-UDisks2-Block.HintSystem

class ProjectsList:
	project_dir
	
	__init__(projects_dir_path):
		this.project_dir = Gio.File.new_for_path(project_dir_path)
		this.project_dir.enumerate_children(
		"", Gio.FileQueryInfoFlags.NONE, null,
		this.cb)
	
	cb(file_enumerator, result):
	
	move_up():
	
	move_down():
	
	activate_project():

class Overview:
	container
	
	constructor(projects):
		this.projects_dirs = []
		# when a disk is mounted, add its "projects" directory to the list
		
		this.container = Gtk.Stack()
		
		this.container.set_halign(Gtk.Align.CENTER)
		this.container.set_valign(Gtk.Align.CENTER)
	
	activate_project(project_dir):
		# if project_uri is in project_views, bring it up
		# otherwise create a new Project
	
	on_project_activated(callback):
		# hide overview when a project is activated;
		
		callback(this.selected_project_dir)
