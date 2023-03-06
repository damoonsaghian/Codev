import subprocess

import 'gi'
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("GtkSource", "5.0")
gi.require_version("Webkit2", "5.0")
gi.require_version("Gst", "1.0")

from gi.repository import GLib, Gio, Gdk, Gtk

from overview import Overview

# https://pygobject.readthedocs.io/en/latest/
# https://github.com/GNOME/pygobject/tree/master/examples/demo/demos
# https://lazka.github.io/pgi-docs/main.html
# https://www.gtk.org/docs/apis/
# https://developer.gnome.org/documentation/

# create a project group -> ask user for the disk

# floating layer to view web'pages, images and videos

# when renaming files or directories in comshell, watch (using inotify) the directory that
# contains the project group which this project belongs to, and log all renames
# there is a log file for each project; the log files are kept in a directory named ".renames",
# inside the projects group directory
# during backup, first rename the files according to this list then do rsync
# https://www.linuxjournal.com/content/linux-filesystem-events-inotify
# https://stackoverflow.com/questions/44651492/can-i-monitor-the-file-re-name-event-on-linux
# https://pypi.org/project/inotify/
# https://pythonhosted.org/watchdog/
# https://stackoverflow.com/questions/26932459/linux-inotify-events-for-rename-with-overwrite
# http://www.pkrc.net/detect-inode-moves.html
# https://github.com/wapsi/smart-rsync-backup

# keep backup path in ".cache/codev/backup-uuid"
# do not follow mount points when making backups
# backup (encrypted) private keys, plus public keys of trusted pairs
# key update between pairs occures only when the backup device is connected

# libarchive (zip, iso, ...)

# .iso file: ask if you want to extract it, if not ask for a device to write it into, then:
# ; sd flash devicename isofile

# screenshot ...
# sleep 3; grim .data/...
# show countdown in status'bar
# insert the image path in buffer

# notifications:
# create a layer in the bottom'left corner, to print notifications, using:
# python3-cffi + wlroots (layer-shell) + python3-cairocffi
# https://cffi.readthedocs.io/en/latest/
# https://cairocffi.readthedocs.io/en/stable/
# at startup scan email boxes of projects, and show notifications
# during the runtime add/remove notifications

# slightly dim unfocused panels
# when moving or when "action" is pressed, create a flash which shows the location of the cursor

Gtk.init(null)

projects = Gtk.Stack()

overview = Overview(projects)

main_view = Gtk.Overlay()
main_view.add(projects)
main_view.add_overlay(overview.container)
# keybinding to show the overview;

win = new Gtk.Window()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", gtk.main_quit)
win.show_all()
win.maximize()
gtk.main()
