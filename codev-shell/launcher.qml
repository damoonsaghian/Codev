// run apps with:
// sudo -u "$USER" ...

// the first item is "system" that executes "system ext-menu", read its stdout,
// shows it in a list for the user to choose, feeds the answer to stdin of the executed command
// this ends when the command terminates (ie when EOF is send to stdout of the command)

// in "system" if the entered text contains spaces run it in a terminal emulator view

// an item for screenshot and screencast
// put in clipboard
// grim -o "$$HOME/.cache/screen.png" | wl-copy --type text/uri-list "file://$$HOME/.cache/screen.png"

// don't close launcher, if workspace is empty

// escape: close launcher

/*
Launcher is a floating layer containing a search entry, and a list of apps

search entry on:
, searchchanged
	if len(search_entry) == 0:
		self.selected_item = self.apps_list.get_item(0)
		flowbox_child = self.apps_flowbox.get_child_at_index(0)
		if flowbox_child:
			self.apps_flowbox.select_child(flowbox_child)
		return
	
	search_pattern = search_entry.text.replace(" ", ".*")
	i = 0
	
	while true:
		item :Gio.AppInfo|None = self.apps_list.get_item(i)
		if not item:
			break
		if re.compile(search_pattern).match(item.get_name()):
			self.selected_item = item
			flowbox_child = self.apps_flowbox.get_child_at_index(i)
			if flowbox_child:
				self.apps_flowbox.select_child(flowbox_child)
			break
		i+=1
, activate
	app_item = self.selected_item
	
	app_name = app_item.get_name()
	subprocess.run([
		'swaymsg',
		f'[app_id=codev] move workspace {app_name}; workspace {app_name}' 
	])
	
	if not subprocess.run(['swaymsg', '[floating] focus']):
		subprocess.run(['swaymsg', 'exec ' + app_item.get_executable()])
	
	subprocess.run(['swaymsg', '[app_id=swapps] move scratchpad'])
	
	# if entry starts with a punctuation character, run it as a command
, notify:has-focus: delete text

app list is a flowbox whose model is a list store that will be updated when .desktop files of apps changes
	def compare_apps(self, app1 :Gio.AppInfo, app2 :Gio.AppInfo):
		app1_name = app1.get_name()
		app2_name = app2.get_name()
		if app2_name > app1_name:
			return -1
		if app1_name > app2_name:
			return 1
		return 0
	def update_apps_list(self):
		self.apps_list.remove_all()
		for app in Gio.AppInfo.get_all():
			if app.should_show():
				self.apps_list.insert_sorted(app, self.compare_apps)
		settings_app = Gio.AppInfo.create_from_commandline("settings")
		self.apps_list.insert(0, settings_app)
	def create_widget(self, app_item :Gio.AppInfo):
		app_name = app_item.get_name()
		label = Gtk.Label(
			label = app_name,
			justify = Gtk.Justification.CENTER,
			width_chars = 20
		)
		icon = app_item.get_icon()
		if not icon:
			if app_name = "settings":
				icon = Gio.ThemedIcon("applications-system-symbolic")
			else:
				icon = Gio.ThemedIcon("")
		icon_image = Gtk.Image.new_from_gicon(icon)
		widget = Gtk.Box(orientation = Gtk.Orientation.VERTICAL, spacing = 5)
		widget.append(icon_image)
		widget.append(label)
		return widget
the first element is selected by default
when an item in the flowbox is clicked, run the app
	selected_child :Gtk.FlowBoxChild = apps_flowbox.get_selected_children()[0]
	index = selected_child.get_index()
	self.selected_item = self.apps_list.get_item(index)
	self.on_activate()
*/

// https://qalculate.github.io/
