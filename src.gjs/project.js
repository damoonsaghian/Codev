import gLib from 'gi://GLib';
import gio from 'gi://Gio';
import gdk from 'gi://Gdk?version=4.0';
import gtk from 'gi://Gtk?version=4.0';

import Files from "files"
import Editor from "editor"
import Gallery from "gallery"

// floating layer to view web'pages, images and videos

// if there is a saved session file for the project, restore it

// backup: two'way diff

const Project = gtk.Widget.extend(function() {
	this.main_view = new gtk.Stack();
	
	this.overlay = new gtk.Stack();
	
	this.container = new gtk.Overlay();
	this.container.add(this.main_view);
	this.container.add_overlay(this.overlay);
})

export default Project