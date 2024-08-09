import gi
gi.require_version('Gdk', '4.0')
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gio, Gdk, Gtk

# in the left panel show the storage devices, and the group directories inside them
# /dev/disk/by-uuid

# use gvfs for remote devices: mtp afc nfs smb avahi ...

# ask the user if she wants to format the device, if:
# , it's not formatted
# , it's a non'system device whose format is not vfat/exfat
# , it's a system device whose format is not btrfs

# to format it, first get the volume identifier
# use "sd" program to format non'system devices with vfat or exfat (if wants files bigger than 4GB)
# for system devices:
# ; sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"

# projects on VFAT/exFAT formated devices, or remote devices, will be opened as read'only
# when you try to edit them, you will be asked to copy them into a local device

# use "sd" program to mount the device (if it's not)

# new messages and upcoming schedules
# show indicators on overview
# send notifications to be shown in the tray area of the statusbar

# https://docs.gtk.org/gtk4/class.ListBox.html

class Overview(Gtk.Widget):
	def __init__(self):
		self.widget = Gtk.Stack()
		self.project_views = Gtk.Stack()
		
		# when a project is selected, hide overview, and return the project's path
	
	def open_project():
		# if project'path is in project'views, bring it up; otherwise create a new Project
