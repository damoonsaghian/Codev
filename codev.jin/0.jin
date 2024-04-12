init = {
	project'views = gui.Stack()
	
	overview = Overview project'views
	
	main'view = gui.Overlay()
	main'view.add project'views
	main'view.add'overlay overview
	
	;; keybinding to show the overview
	
	win = gui.Window()
	win.add main'view
}
