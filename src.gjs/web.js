import gLib from 'gi://GLib';
import gio from 'gi://Gio';
import gdk from 'gi://Gdk?version=4.0';
import gtk from 'gi://Gtk?version=4.0';
import webkit from 'gi://Webkit?version=6.0';

import Scroll from "scroll"

/*
https://github.com/sonnyp/Tangram
https://www.archlinux.org/packages/community/any/eolie/
https://github.com/liske/barkery

non'English pages are managed using a userscript
on non'English pages:
, activate the relevant keyboard layout
, show keyboard layout indicator near cursor
, provide a keybinding to switch between keyboard layouts
if a page contains non'latin characters, and web fonts are not provided, install the relevant Noto web font
if page contains emoji charactors add twemoji web font
https://github.com/twitter/twemoji
*/

const WebView = Scroll.extend(function() {
	this.set_child(new webkit.WebView())
})

export default WebView