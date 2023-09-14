import gLib from 'gi://GLib';
import gio from 'gi://Gio';
import gdk from 'gi://Gdk?version=4.0';
import gtk from 'gi://Gtk?version=4.0';

import { Files } from "files"
import { Editor } from "editor"
import { Gallery } from "gallery"

// floating layer to view web'pages, images and videos

// if there is a saved session file for the project, restore it

// backup: two'way diff

export
const Project = gtk.Overlay.extend({
	main_view: new gtk.Stack(),
	overlay: new gtk.Stack(),
	init() {
		this.add(this.main_view);
		this.add_overlay(this.overlay);
	}
})
