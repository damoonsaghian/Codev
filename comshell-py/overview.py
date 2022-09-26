from gi.repository import Gtk, Gdk, Gio, GLib

from project import Project

# https://docs.gtk.org/gio/class.VolumeMonitor.html

# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Drive.html#gdbus-property-org-freedesktop-UDisks2-Drive.Removable
#
# if the device is removale and not formated with VFAT/exFAT, ask the user if she wants to format it
#   format with VFAT (or exFAT if there would be files bigger than 4GB)
#   http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
# if the device is not removale and not formated with BTRFS, ask the user if she wants to format it
#   pkexec sh /usr/local/share/sd-internal.sh format "$1"
#
# mount
# if removable: udisksctl mount -b /dev/"$1"
# if not removable: pkexec sh /usr/local/share/sd-internal.sh mount "$1"
#
# unmount
# udisksctl unmount -b /dev/"$1"

# after mounting: codev backup mount_path

class ProjectsList:
  project_dir

  __init__(projects_dir_path):
    this.project_dir = Gio.File.new_for_path(project_dir_path)
    this.project_dir.enumerate_children(
      "", Gio.FileQueryInfoFlags.NONE, null,
      this.cb
    )

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
