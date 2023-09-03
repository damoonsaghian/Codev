import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Gdk from 'gi://Gdk?version=4.0';
import Gtk from 'gi://Gtk?version=4.0';

const Files = imports.files;
const Editor = imports.editor;
const Gallery = imports.gallery;

// floating layer to view web'pages, images and videos

// if there is a saved session file for the project, restore it

// backup: two'way diff

export
const Project = Gtk.Widget.extend(function() {
	this.main_view = new Gtk.Stack();
	
	this.overlay = new Gtk.Stack();
	
	this.container = new Gtk.Overlay();
	this.container.add(this.main_view);
	this.container.add_overlay(this.overlay);
})
