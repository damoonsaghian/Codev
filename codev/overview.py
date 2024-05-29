# in the left panel show the storage devices, and the group directories inside them

# ask the user if she wants to format the device, if:
# , it's not formated
# , it's a non'system device whose format is not vfat/exfat
# , it's a system device whose format is not btrfs

# to format it, first get the volume identifier
# use "sd" module to format non'system devices with vfat or exfat (if wants files bigger than 4GB)
# for system devices:
# ; sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"

# projects on VFAT/exFAT formated devices will be opened as read'only
# when you try to edit them, you will be asked to copy them into a BTRFS formated device

# use "sd" module to mount the device (if it's not)

# new messages and upcoming schedules
# show indicators on overview
# send notifications to be shown in the tray area of the statusbar

# https://docs.gtk.org/gtk4/class.ListBox.html

class Overview(Gtk.Widget):
	def __init__():
		self.widget = gui.Stack()
		self.project_views = gui.Stack()
		
		;; when a project is selected, hide overview, and return the project's path
	
	def open_project:
		# if project'path is in project'views, bring it up; otherwise create a new Project
