import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Gdk from 'gi://Gdk?version=4.0';
import Gtk from 'gi://Gtk?version=4.0';
import Webkit from 'gi://Webkit2?version=4.0';

/*
https://www.archlinux.org/packages/community/any/eolie/
https://github.com/liske/barkery
https://github.com/sonnyp/Tangram

non'English pages are managed using a userscript
on non'English pages:
, activate the relevant keyboard layout
, show keyboard layout indicator near cursor
, provide a keybinding to switch between keyboard layouts
if a page contains non'latin characters, and web fonts are not provided, install the relevant Noto web font
if page contains emoji charactors add twemoji web font
https://github.com/twitter/twemoji
*/

export
const Web = Gtk.Widget.extend(function() {})
