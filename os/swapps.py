import subprocess

import gi
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gio, Gdk, Gtk

def create_scroll(widget):
	scrolled_widget = Gtk.ScrolledWindow{
		child = widget,
		hscrollbar_policy = gtk.Policy.Never,
		vscrollbar_policy = gtk.Policy.Never
	}
	
	# use undershoot lines on borders of ScrolledWindow to show the amount of overflowed content
	def update_css_classes():
		vadjust = scrolled_widget.vadjustment
		top_overflow = vadjust.value * 10 // vadjust.upper
		bottom_overflow = (vadjust.upper - vadjust.page_size - vadjust.value)*10 // vadjust.upper
		
		hadjust = scrolled_widget.hadjustment
		left_overflow = hadjust.value * 10 // hadjust.upper
		right_overflow = (hadjust.upper - hadjust.page_size - hadjust.value)*10 // hadjust.upper
		
		scrolled_widget:set_css_class[
			"overflow-t"..top_overflow, "overflow-b"..bottom_overflow,
			"overflow-l"..left_overflow, "overflow-r"..right_overflow
		]
	
	scrolled_widget.vadjustment.on_changed = update_css_classes
	scrolled_widget.hadjustment.on_changed = update_css_classes
	
	return scrolled_widget

def create_app_launcher_view(root_view):
	apps_list = gio.ListStore(Gtk.Application)
	filter = gtk.StringFilter()
	apps_list_filtered = Gtk.FilterListModel(apps_list, filter)
	
	def compare_apps(app1, app2):
		app1_name = app1.get_name()
		app2_name = app2.get_name()
		if app2_name > app1_name:
			return -1
		elif app1_name > app2_name:
			return 1
		else:
			return 0
	
	def update_apps_list():
		apps_list.remove_all()
		for _, app in ipairs(gio.AppInfo.get_all()):
			app_name = app.get_name()
			if app.should_show():
				apps_list.insert_sorted(app, compare_apps)
	update_apps_list()
	Gio.AppInfoMonitor.get().connect('changed', update_apps_list)
	
	def raise_or_run_app(app):
		os.execute('swaymsg workspace ' .. string.format('%q', app:get_name()))
		error_code = os.execute('swaymsg "[con_id=__focused__] focus"')
		if error_code != 0:
			os.execute('swaymsg exec ' .. string.format('%q', app:get_commandline()))
		os.execute("swaymsg move scratchpad")
		# swaymsg "[con_id=codev] focus" || python3 /usr/local/share/codev
		# swaymsg "[app_id=codev] move workspace $app; workspace $app"; app.exec
	
	apps_flowbox = Gtk.FlowBox(
		orientation = gtk.Orientation.HORIZONTAL,
		column_spacing = 5,
		row_spacing = 5,
		margin_top = 5, margin_bottom = 5, margin_start = 5, margin_end = 5,
		selection_mode = gtk.SelectionMode.NONE,
		focusable = false
	)
	apps_flowbox.bind_model(apps_list_filtered, function(app)
		local label = gtk.Label{
			label = app:get_name(),
			justify = gtk.Justification.CENTER,
			width_chars = 20
		}
		
		local icon = gtk.Image.new_from_gicon(app:get_icon())
				
		local event_controller = gtk.EventControllerKey()
		event_controller.on_key_pressed = function(_, keyval)
			if keyval == gdk.BUTTON_PRIMARY then raise_or_run_app(app) end
		end
		
		local widget = gtk.Box{
			orientation = gtk.Orientation.VERTICAL,
			spacing = 5
		}
		widget:append(label)
		widget:append(icon)
		widget:add_controller(event_controller)
		return widget
	end)
	
	search_entry = Gtk.SearchEntry(placeholder_text = 'press "space" to go to terminal')
	
	search_entry.search_changed = function(search_entry)
		filter:set_search(string:gsub(search_entry.text, " ", ".* "))
		
		# pressing "space" when search entry is empty -> go to terminal view
		# root_view.set_current_page(1)
		# pressing "comma" -> go to session manager
		# root_view.set_current_page(2)
	end
	
	search_entry.on_activate = function()
		raise_or_run_app(apps_list_filtered:get_item(0))
	end
	
	caption = Gtk.Label(label = '\tpress "comma" to activate session manager')
	caption.set_css_class(["dim-label", "caption"])
		
	app_launcher_view = Gtk.Box(gtk.Orientation.VERTICAL, 0)
	app_launcher_view.append(search_entry)
	app_launcher_view.append(caption)
	app_launcher_view.append(create_scroll(apps_flowbox))
	return app_launcher_view

def create_terminal_view():
	terminal_view = create_scroll(vte.Terminal())
	
	# entering a space at the beginning -> open a new terminal window (whose app_id is not swayapps)
	
	# enter "system" to configure system settings
	
	# pageup
	# pagedown
	# ctrl+c
	# ctrl+v
	# ctrll+n or ctrl+t: new terminal
	# ctrl+f
	# esc: enter \x03 (ctrl+c) character
	
	# background=000000
	# foreground=FFFFFF
	# regular0=403E41
	# regular1=FF6188
	# regular2=A9DC76
	# regular3=FFD866
	# regular4=FC9867
	# regular5=AB9DF2
	# regular6=78DCE8
	# regular7=FCFCFA
	# bright0=727072
	# bright1=FF6188
	# bright2=A9DC76
	# bright3=FFD866
	# bright4=FC9867
	# bright5=AB9DF2
	# bright6=78DCE8
	# bright7=FCFCFA
	# selection-background=555555
	# selection-foreground=dddddd
	
	return terminal_view

def create_session_manager_view():
	session_manager_list = Gio.ListStore(glib.HashTable)
	filter = Gtk.StringFilter()
	session_manager_list_filtered = Gtk.FilterListModel(session_manager_list, filter)
	
	session_manager_list.insert{
		name = 'lock',
		icon_name = 'system-lock-screen-symbolic',
		command = '/usr/local/bin/lock'
	}
	session_manager_list.insert{
		name = 'suspend',
		icon_name = 'media-playback-pause-symbolic',
		command = 'systemctl suspend'
	}
	session_manager_list.insert{
		name = 'exit',
		icon_name = 'system-log-out-symbolic',
		command = 'swaymsg exit'
	}
	session_manager_list.insert{
		name = 'reboot',
		icon_name = 'system-reboot-symbolic',
		command = 'systemctl reboot'
	}
	session_manager_list.insert{
		name = 'poweroff',
		icon_name = 'system-shutdown-symbolic',
		command = 'systemctl poweroff'
	}
	
	session_manager_flowbox = Gtk.FlowBox{
		orientation = gtk.Orientation.HORIZONTAL,
		column_spacing = 5,
		row_spacing = 5,
		margin_top = 5, margin_bottom = 5, margin_start = 5, margin_end = 5,
		selection_mode = gtk.SelectionMode.NONE,
		focusable = false
	}
	session_manager_flowbox.bind_model(session_manager_list_filtered, function(sm_item)
		label = Gtk.Label{
			label = sm_item.name,
			justify = gtk.Justification.CENTER,
			width_chars = 20
		}
		
		icon = Gtk.Image.new_from_gicon(sm_item.icon_name)
				
		event_controller = Gtk.EventControllerKey()
		event_controller.on_key_pressed = function(_, keyval)
			if keyval == gdk.BUTTON_PRIMARY then os.execute(sm_item.command) end
		end
		
		widget = Gtk.Box{
			orientation = gtk.Orientation.VERTICAL,
			spacing = 5
		}
		widget.append(label)
		widget.append(icon)
		widget.add_controller(event_controller)
		return widget
	end)
	
	search_entry = Gtk.SearchEntry()
	
	search_entry.search_changed = function(search_entry)
		filter:set_search(string:gsub(search_entry.text, " ", ".* "))
	end
	
	search_entry.on_activate = function()
		os.execute(session_manager_list_filtered:get_item(0).command)
	end
	
	session_manager_view = Gtk.Box(Gtk.Orientation.VERTICAL, 0)
	session_manager_view.append(search_entry)
	session_manager_view.append(create_scroll(session_manager_flowbox))
	return session_manager_view

app = Gtk.Application(application_id='swayapps')

def on_startup(app):
	search_entry = Gtk.TextView()
	
	root_view = Gtk.Notebook()
	root_view.append_page(create_app_launcher_view(root_view), Gtk.Label("apps"))
	root_view.append_page(create_session_manager_view(), gtk.Label("session"))
	
	css_provider = Gtk.CssProvider()
	css_provider.load_from_string('''
	scrolledwindow undershoot.top {
		background-color: transparent;
		background-image: linear-gradient(to left, rgba(255, 255, 255, 0.2) 50%, rgba(0, 0, 0, 0.2) 50%);
		padding-top: 1px;
		background-size: 20px 1px;
		background-repeat: repeat-x;
		background-origin: content-box;
		background-position: center top; }
	scrolledwindow undershoot.bottom {
		background-color: transparent;
		background-image: linear-gradient(to left, rgba(255, 255, 255, 0.2) 50%, rgba(0, 0, 0, 0.2) 50%);
		padding-bottom: 1px;
		background-size: 20px 1px;
		background-repeat: repeat-x;
		background-origin: content-box;
		background-position: center bottom; }
	scrolledwindow undershoot.left {
		background-color: transparent;
		background-image: linear-gradient(to top, rgba(255, 255, 255, 0.2) 50%, rgba(0, 0, 0, 0.2) 50%);
		padding-left: 1px;
		background-size: 1px 20px;
		background-repeat: repeat-y;
		background-origin: content-box;
		background-position: left center; }
	scrolledwindow undershoot.right {
		background-color: transparent;
		background-image: linear-gradient(to top, rgba(255, 255, 255, 0.2) 50%, rgba(0, 0, 0, 0.2) 50%);
		padding-right: 1px;
		background-size: 1px 20px;
		background-repeat: repeat-y;
		background-origin: content-box;
		background-position: right center; }
	
	scrolledwindow.overflow-t2 undershoot.top { background-size: 18px 1px; }
	scrolledwindow.overflow-b2 undershoot.bottom { background-size: 18px 1px; }
	scrolledwindow.overflow-l2 undershoot.left { background-size: 1px 18px; }
	scrolledwindow.overflow-r2 undershoot.righ { background-size: 1px 18px; }
	
	scrolledwindow.overflow-t3 undershoot.top { background-size: 16px 1px; }
	scrolledwindow.overflow-b3 undershoot.bottom { background-size: 16px 1px; }
	scrolledwindow.overflow-l3 undershoot.left { background-size: 1px 16px; }
	scrolledwindow.overflow-r3 undershoot.righ { background-size: 1px 16px; }
	
	scrolledwindow.overflow-t4 undershoot.top { background-size: 14px 1px; }
	scrolledwindow.overflow-b4 undershoot.bottom { background-size: 14px 1px; }
	scrolledwindow.overflow-l4 undershoot.left { background-size: 1px 14px; }
	scrolledwindow.overflow-r4 undershoot.righ { background-size: 1px 14px; }
	
	scrolledwindow.overflow-t5 undershoot.top { background-size: 12px 1px; }
	scrolledwindow.overflow-b5 undershoot.bottom { background-size: 12px 1px; }
	scrolledwindow.overflow-l5 undershoot.left { background-size: 1px 12px; }
	scrolledwindow.overflow-r5 undershoot.righ { background-size: 1px 12px; }
	
	scrolledwindow.overflow-t6 undershoot.top { background-size: 10px 1px; }
	scrolledwindow.overflow-b6 undershoot.bottom { background-size: 10px 1px; }
	scrolledwindow.overflow-l6 undershoot.left { background-size: 1px 10px; }
	scrolledwindow.overflow-r6 undershoot.righ { background-size: 1px 10px; }
	
	scrolledwindow.overflow-t7 undershoot.top { background-size: 8px 1px; }
	scrolledwindow.overflow-b7 undershoot.bottom { background-size: 8px 1px; }
	scrolledwindow.overflow-l7 undershoot.left { background-size: 1px 8px; }
	scrolledwindow.overflow-r7 undershoot.righ { background-size: 1px 8px; }
	
	scrolledwindow.overflow-t8 undershoot.top { background-size: 6px 1px; }
	scrolledwindow.overflow-b8 undershoot.bottom { background-size: 6px 1px; }
	scrolledwindow.overflow-l8 undershoot.left { background-size: 1px 6px; }
	scrolledwindow.overflow-r8 undershoot.righ { background-size: 1px 6px; }
	
	scrolledwindow.overflow-t9 undershoot.top { background-size: 4px 1px; }
	scrolledwindow.overflow-b9 undershoot.bottom { background-size: 4px 1px; }
	scrolledwindow.overflow-l9 undershoot.left { background-size: 1px 4px; }
	scrolledwindow.overflow-r9 undershoot.righ { background-size: 1px 4px; }
	
	scrolledwindow.overflow-t10 undershoot.top { background-size: 2px 1px; }
	scrolledwindow.overflow-b10 undershoot.bottom { background-size: 2px 1px; }
	scrolledwindow.overflow-l10 undershoot.left { background-size: 1px 2px; }
	scrolledwindow.overflow-r10 undershoot.righ { background-size: 1px 2px; }
	''')
	Gtk.StyleContext.add_provider_for_display(
		Gdk.Display.get_default(),
		css_provider,
		Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
	)
	
	win = Gtk.ApplicationWindow(application=app)
	win.set_child(root_view)
	win.present()
	
	# when window is focused, go to app view
	
	# when window is unfocused:
	# swaymsg "[con_id=codev] focus" || python3 /usr/local/share/codev

app = Gtk.Application(application_id='swapps')
app.connect('startup', on_startup)
app.connect('activate', lambda: subprocess.run(['swaymsg', '[app_id=swapps] focus']))
app.run(None)
