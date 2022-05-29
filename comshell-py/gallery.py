from gi.repository import Gtk, Gdk, Gio, GLib, Gst

# for gallery view: gtk::FlowBox, gtk::Scrollable
# https://github.com/karlch/vimiv
# https://gitlab.com/Strit/griffith
# https://gitlab.gnome.org/GNOME/shotwell/tree/master/src
# https://gitlab.gnome.org/GNOME/gnome-music
# https://gitlab.gnome.org/World/lollypop/-/tree/master/lollypop
# https://github.com/quodlibet/quodlibet/
# https://gitlab.gnome.org/GNOME/pitivi/-/tree/master/pitivi
# https://github.com/jliljebl/flowblade

# subtitles and comments
# https://github.com/otsaloma/gaupol/tree/master/gaupol

# libgdk-pixbuf2.0-bin (thumbnailer)
# gdk-pixbuf-thumbnailer -s 128 %u %o

class Gallery:
  container
  file_icon
  dir_icon
  store
  view

  __init__():
    this.container = Gtk.ScrolledWindow()
    this.container.set_policy(Gtk.POLICY_AUTOMATIC, Gtk.POLICY_AUTOMATIC)

    theme = Gtk.iconThemeGetDefault()
    this.file_icon = theme.loadIcon(Gtk.STOCK_FILE, 48, 0)
    this.dir_icon = theme.loadIcon(Gtk.STOCK_DIRECTORY, 48, 0)

    this.store = Gtk.ListStore(str, Gtk.gdk.Pixbuf, bool)
    this.store.set_sort_column_id(0, Gtk.SORT_ASCENDING)
    this.store.clear()

    this.view = Gtk.IconView()

  move_up():

  move_down():

  go_to_item():

  find():
