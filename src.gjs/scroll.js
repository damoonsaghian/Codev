import glib from 'gi://GLib'
import gio from 'gi://Gio'
import gdk from 'gi://Gdk?version=4.0'
import gtk from 'gi://Gtk?version=4.0'

// use colored lines on top and bottom of scrollables to show the amount of content above and below
// when scroll changes, change the color of undershoot by changing it's css class
// https://gist.github.com/epedroni/03e6058de2769e67ed00

let style_provider = new gtk.CssProvider()
let css_path =
style_provider.load_from_file(gio.File.new_for_path(css_path))
gtk.StyleContext.add_provider_for_screen(
	gdk.Screen.get_default(),
	style_provider,
	gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

const Scroll = gtk.ScrolledWindow.extend({
	init() {
		this.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
	}
})

export default Scroll
