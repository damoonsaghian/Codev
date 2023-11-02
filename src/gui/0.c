/*
multi'threaded GUI (which GTK is not):
	container widget asks the children to stop drawing, and after receiving their reply, cleans their area,
	then sends the new areas to them to draw into
https://www.cairographics.org/threaded_animation_with_cairo/

Widget Widget'i Window Stack Overlay

win.set'titlebar null
win.connect 'destroy gtk.main'quit
win.show'all()
win.maximize()
*/

/*
https://docs.gtk.org/gtk4/class.DirectoryList.html

https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
https://github.com/tchx84/Portfolio
http://zetcode.com/gui/pygtk/advancedwidgets/
https://github.com/MeanEYE/Sunflower
https://gitlab.xfce.org/apps/catfish/
https://gitlab.gnome.org/aviwad/organizer

https://github.com/donadigo/elementary-ide
*/

/*
https://gitlab.gnome.org/GNOME/gtk/-/blob/main/docs/text_widget_internals.txt
https://gnome.pages.gitlab.gnome.org/gtksourceview/gtksourceview5/

https://github.com/sonnyp/Workbench
https://github.com/sriske2/umte/blob/master/umte.py
https://github.com/Axel-Erfurt/TextEdit/blob/main/TextEdit.py
https://gitlab.gnome.org/World/apostrophe
https://github.com/jendrikseipp/rednotebook
https://github.com/zim-desktop-wiki/zim-desktop-wiki
https://github.com/TenderOwl/Norka/
https://gitlab.gnome.org/GNOME/meld/-/tree/master/meld
https://github.com/MightyCreak/diffuse

indentation guides:
change the background color of leading tabs; interchange between 2 colors

https://gitlab.gnome.org/GNOME/gspell
*/

/*
for gallery view: gtk.Flow'box, gtk.Scrollable
https://github.com/karlch/vimiv
https://gitlab.com/Strit/griffith
https://gitlab.gnome.org/GNOME/shotwell/tree/master/src
https://gitlab.gnome.org/World/vocalis
https://gitlab.gnome.org/GNOME/gnome-music
https://gitlab.gnome.org/World/lollypop/-/tree/master/lollypop
https://github.com/quodlibet/quodlibet/
https://gitlab.gnome.org/GNOME/pitivi/-/tree/master/pitivi
https://github.com/jliljebl/flowblade

gdk-pixbuf-thumbnailer -s 128 %u %o

Generic Graphics Library is a graph based image processing framework
https://packages.debian.org/bookworm/libgegl-dev

gtk4 mediafile

subtitles and comments
https://github.com/otsaloma/gaupol/tree/master/gaupol

gtk'application'inhibit gtk'application'uninhibit
*/

/*
https://github.com/sonnyp/Tangram
https://www.archlinux.org/packages/community/any/eolie/
https://github.com/liske/barkery
*/

/*
use colored lines on top and bottom of scrollables to show the amount of content above and below
create css classes for undershoot, with various colors
https://gist.github.com/epedroni/03e6058de2769e67ed00
when scroll changes, change the css class of undershoot
let style'provider = gtk.Css'provider.new()
let css'path =
style'provider.load'from'file(gio.File.new'for'path(css'path))
gtk.Style'context.add'provider'for'screen(
	gdk.Screen.get'default(),
	style'provider,
	gtk.STYLE'PROVIDER'PRIORITY'APPLICATION
)

slightly dim unfocused panels
*/

/*
WYSIWYG editor for formula and 2D/3D models
cursor movement represents the movement inside the tree
https://github.com/alexhuntley/Plots
https://github.com/gaphor/gaphor
https://github.com/jrfonseca/xdot.py
https://github.com/dubstar-04/Design
https://gitlab.gnome.org/GNOME/gnome-weather/
https://gitlab.gnome.org/GNOME/gnome-maps
make graphical elements from Gsk cairo and opengl nodes, inside transform nodes
https://docs.gtk.org/gtk4/class.Snapshot.html
*/
