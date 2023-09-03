import GLib from 'gi://GLib'
import Gio from 'gi://Gio'
import Gdk from 'gi://Gdk?version=4.0'
import Gtk from 'gi://Gtk?version=4.0'

import GObject from 'gi://GObject'
GObject.Object.prototype.extend = function(init, ...interfaces) {
	return GObject.registerClass({
		Implements: interfaces
	}, class extends this {
		constructor(arg) {
			super()
			init.bind(this, arg)
		}
	})
}
GObject.TypeInstance.prototype.extend = GObject.prototype.extend

const { Overview } = imports.overview

/*
for implementing a prototype of Codev, it seems that the best tool at hand is GJS

https://github.com/donadigo/elementary-ide

slightly dim unfocused panels

new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

use colored lines on top and bottom of scrollables to show the amount of content above and below
local style_provider = Gtk.CssProvider()
local css_path =
style_provider.load_from_file(Gio.File.new_for_path(css_path))
Gtk.StyleContext.add_provider_for_screen(
	Gdk.Screen.get_default(),
	style_provider,
	Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

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

const projects = new Gtk.Stack()

const overview = new Overview(projects)

const main_view = new Gtk.Overlay()
main_view.add(projects)
main_view.add_overlay(overview.container)
// keybinding to show the overview;

const win = new Gtk.Window()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", Gtk.main_quit)
win.show_all()
win.maximize()
Gtk.main()
