import glib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'

import gobject from 'gi://GObject'
gobject.Object.prototype.extend = function(init, ...interfaces) {
	return GObject.registerClass({
		Implements: interfaces
	}, class extends this {
		constructor(arg) {
			super(arg)
			init.call(this, arg)
		}
	})
}
gobject.TypeInstance.prototype.extend = gobject.prototype.extend

import { Overview } from "overview"

/*
https://github.com/donadigo/elementary-ide

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
