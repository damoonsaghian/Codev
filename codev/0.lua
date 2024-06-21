function main()	
	local app = gtk.Application { application_id = "codev" }
		
	app.on_activate = function(app)
		local win = app:get_windows()[1]
		if not win then
			-- base_dir = os.path.abspath(os.path.dirname(__file__))
			-- css_path = os.path.join(base_dir, 'input_paste.css')
			
			local project_views = gtk.Stack()
			
			local overview = Overview(project_views)
			
			local root_view = gtk.Overlay()
			main_view:add(project_views)
			main_view:add_overlay(overview.container)
			-- keybinding to show the overview;
			
			--[[
			when window is unfocused, make it insensitive
			
			when window is focused, make it sensitive again, then:
			swaymsg "[workspace=__focused__ floating] focus" && {
				swaymsg "[workspace=codev floating] move scratchpad; [app_id=swapps] move scratchpad;
					[app_id=codev] move workspace codev; workspace codev; [app_id=codev] focus"
			}
			]]
			
			win = gtk.ApplicationWindow { application = app }
			win:maximize()
			win:set_titlebar()
			win:set_child(root_view)
			win:connect("destroy", gtk.main_quit)
		end
		win.present()
	end
	
	app:run()
end
