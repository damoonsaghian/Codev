import glib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'

Object.prototype.extend = function(class_object, ...interfaces) {
	let new_class = GObject.registerClass({
		Implements: interfaces
	}, class extends this {
		constructor(arg) {
			super()
			for (property in arg) {
				this[property] = arg[property]
			}
			this.init()
		}
	})
	
	for (property in class_object) {
		new_class.prototype[property] = class_object[property]
	}
	
	return new_class
}

import { Overview } from "overview"

/*
https://github.com/donadigo/elementary-ide

use colored lines on top and bottom of scrollables to show the amount of content above and below
create css classes for undershoot, with various colors
https://gist.github.com/epedroni/03e6058de2769e67ed00

let style_provider = new gtk.CssProvider()
let css_path =
style_provider.load_from_file(gio.File.new_for_path(css_path))
gtk.StyleContext.add_provider_for_screen(
	gdk.Screen.get_default(),
	style_provider,
	gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

slightly dim unfocused panels

new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

GNUnet: audio conversasion is already implemented
https://git.gnunet.org/gnunet.git/tree/src/conversation
https://git.gnunet.org/gnunet.git/tree/src/conversation/gnunet_gst.c
https://manpages.debian.org/unstable/gnunet/gnunet-conversation.1.en.html
https://jami.net/
https://packages.debian.org/bookworm/jami-daemon
figure out how to send/receive streams to/from gnunet
use gstreamer gio plugin to send/receive streams to/from gstreamer
use gstreamer pipewire plugin to access camera
	libaperture, libaravis
use gtk4 mediafile to put it on gui
*/

const projects = new gtk.Stack()

const overview = new Overview(projects)

const main_view = new gtk.Overlay()
main_view.add(projects)
main_view.add_overlay(overview.container)
// keybinding to show the overview;

const win = new gtk.Window()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", Gtk.main_quit)
win.show_all()
win.maximize()
gtk.main()
