import gi
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gio, Gdk, Gtk

project_views = Gtk.Stack()

overview = Overview(project_views)

main_view = Gtk.Overlay()
main_view.add(project_views)
main_view.add_overlay(overview)
	
# keybinding to show the overview

win = Gtk.Window()
win.add(main_view)

# when window is unfocused, make it insensitive

# when window is focused, make it sensitive again, then:
# swaymsg "[workspace=__focused__ floating] focus" && {
# 	swaymsg "[workspace=codev floating] move scratchpad; [app_id=swapps] move scratchpad;
# 		[app_id=codev] move workspace codev; workspace codev; [app_id=codev] focus"
# }
