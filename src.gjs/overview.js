import gLib from 'gi://GLib';
import gio from 'gi://Gio';
import gdk from 'gi://Gdk?version=4.0';
import gtk from 'gi://Gtk?version=4.0';

import { Project } from "project"

/*
left panel

attached devices:
https://docs.gtk.org/gio/class.VolumeMonitor.html

ask the user if she wants to format the device, if:
, it's not formated
, it's a non'system device whose format is not vfat/exfat
, it's a system device whose format is not btrfs
http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-property-org-freedesktop-UDisks2-Block.HintSystem
http://storaged.org/doc/udisks2-api/latest/index.html
https://lazka.github.io/pgi-docs/#Gio-2.0/classes/DBusConnection.html
https://gjs.guide/guides/gio/dbus.html#direct-calls
https://gjs.guide/guides/glib/gvariant.html#basic-usage

to format it get the volume identifier
https://docs.gtk.org/gio/iface.Volume.html
use udisks to format non'system devices with vfat or exfat (if wants files bigger than 4GB)
http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
type: fat
mkfs-args: -F, 32, -I (to override partitions)
for system devices:
; sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"

projects on VFAT/exFAT formated devices will be opened as read'only
when you try to edit them, you will be asked to copy them on to a BTRFS formated device

mount it (if it's not)
https://docs.gtk.org/gio/method.Volume.mount.html
*/

const ProjectsList = Scroll.extend({
	init() {
		let projects_dir_path = arg.projects_dir_path
		this.project_dir = gio.File.new_for_path(projects_dir_path)
		this.project_dir.enumerate_children(
			"", gio.FileQueryInfoFlags.NONE, null,
			function(file_enumerator, result) {}
		)
		// when scroll changes, change the css class of undershoot
	},
	
	move_up() {},
	
	move_down() {},

	activate_project() {}
})

export
const Overview = gtk.Widget.extend({
	project_dirs: [],
	container: gtk.Stack(),
	init() {
		// when a disk is mounted, add it to "project_dirs"
		this.container.set_halign(gtk.Align.CENTER)
		this.container.set_valign(gtk.Align.CENTER)
	},
	activate_project(project_dir) {
		// if project_uri is in project_views, bring it up
		// otherwise create a new Project
	},
	on_project_activated(callback) {
		// hide overview when a project is activated;
		
		callback(this.selected_project_dir)
	}
})
