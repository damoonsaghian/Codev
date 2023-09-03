import GLib from 'gi://GLib'
import Gio from 'gi://Gio'
import Gdk from 'gi://Gdk?version=4.0'
import Gtk from 'gi://Gtk?version=4.0'
import GtkSource from 'gi://GtkSource?version=5.0'

/*
https://gitlab.gnome.org/GNOME/gtk/-/blob/main/docs/text_widget_internals.txt
https://gnome.pages.gitlab.gnome.org/gtksourceview/gtksourceview5/

https://github.com/sriske2/umte/blob/master/umte.py
https://github.com/Axel-Erfurt/TextEdit/blob/main/TextEdit.py
https://gitlab.gnome.org/World/apostrophe
https://github.com/jendrikseipp/rednotebook
https://github.com/zim-desktop-wiki/zim-desktop-wiki
https://github.com/TenderOwl/Norka/
https://gitlab.gnome.org/GNOME/meld/-/tree/master/meld
https://github.com/MightyCreak/diffuse

next and previous: word, line, paragraph

indentation guides:
change the background color of leading tabs; interchange between 2 colors

"psi" followed by two succesive apostrophes will be replaced by "ψ"

white space (space, tab, new line) + space -> tab

elastic tabstops: "http://nickgravgaard.com/elastic-tabstops/"
https://docs.gtk.org/gtk4/property.TextTag.tabs.html

store and restore undo history
https://stackoverflow.com/questions/76096/undo-with-gtk-textview

WYSIWYG editor for formula and 2D/3D models
cursor movement represents the movement inside the tree
https://github.com/alexhuntley/Plots
https://github.com/gaphor/gaphor
https://github.com/jrfonseca/xdot.py
make graphical elements from Gsk cairo and opengl nodes, inside transform nodes
https://docs.gtk.org/gtk4/class.Snapshot.html

https://gitlab.gnome.org/GNOME/gspell

clipboard handling for text, image, and "text/uri-list"
for the latter, ref'copy the files into the ".data" directory,
ask for a name, and insert the path into the text buffer

screen recording: gstreamer1.0-pipewire (like in Kooha, and GnomeShell)
to insert a screenshot or screencast:
move the file saved in "~/.cache/screen.png" or "~/.cache/screen.mp4" to ".data"
ask for a name, and insert the path into the text buffer
*/

export
const Editor = Gtk.Widget.extend()
