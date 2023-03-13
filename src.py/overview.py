from gi.repository import GLib, Gio, Gdk, Gtk

from project import Project

# left panel
#
# attached devices:
# https://docs.gtk.org/gio/class.VolumeMonitor.html
#
# format: sd format vfat /dev/sdx
# , removable: vfat
# , removable containing files bigger than 4GB: exfat
# , internal: btrfs
#
# projects on VFAT/exFAT devices will be opened as read'only
# when you try to edit them, you will be asked to copy them on to a BTRFS device
#
# mount it if it's not:
# ; sd mount $device_name
# the device will be mounted in ~/.local/sd-mount/$device_name
# to unmount:
# ; sd unmount $device_name

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
