Function.prototype.extend = function(class_object, ...interfaces) {
	let NewClass = class extends this {
		constructor(arg) {
			super()
			for (property in arg) {
				this[property] = arg[property]
			}
			if (this.init) this.init()
		}
	}
	
	for (const iface of interfaces) {
		for (const property in iface) {
			NewClass.prototype[property] = iface[property]
		}
	}
	
	for (const property in class_object) {
		NewClass.prototype[property] = class_object[property]
	}
	
	return NewClass
}

import gobject from 'gi://GObject'
gobject.Object.extend = function(class_object, ...interfaces) {
	let NewClass = GObject.registerClass({
		Implements: interfaces
	}, class extends this {
		constructor(arg) {
			super()
			for (property in arg) {
				this[property] = arg[property]
			}
			if (this.init) this.init()
		}
	})
	
	for (const property in class_object) {
		NewClass.prototype[property] = class_object[property]
	}
	
	return NewClass
}

import glib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'

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
*/

const project_views = new gtk.Stack()

const overview = new Overview({project_views})

const main_view = new gtk.Overlay()
main_view.add(project_views)
main_view.add_overlay(overview)
// keybinding to show the overview;

const win = new gtk.Window()
win.add(main_view)
win.set_titlebar(null)
win.connect("destroy", gtk.main_quit)
win.show_all()
win.maximize()
gtk.main()
