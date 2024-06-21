-- use undershoot lines on borders of ScrolledWindow to show the amount of overflowed content

function scrollify(widget)
	local scrolled_widget = gtk.ScrolledWindow {
		child = widget,
		hscrollbar_policy = gtk.Policy.Never,
		vscrollbar_policy = gtk.Policy.Never
	}
	
	scrolled_widget.on_notify:connect(function (scrolled_widget)
		local vadjust = scrolled_widget.vadjustment
		local top_overflow = vadjust.value * 10 // vadjust.upper
		local bottom_overflow = (vadjust.upper - vadjust.page_size - vadjust.value) * 10 // vadjust.upper
		
		scrolled_widget.set_css_class["overflow-t"..top_overflow, "overflow-b"..bottom_overflow]
	end, 'vadjustment')
	
	scrolled_widget.on_notify:connect(function ()
		local hadjust = scrolled_widget.hadjustment
		local left_overflow = hadjust.value * 10 // hadjust.upper
		local right_overflow = (hadjust.upper - hadjust.page_size - hadjust.value) * 10 // hadjust.upper
		
		scrolled_widget.set_css_class["overflow-l"..left_overflow, "overflow-r"..right_overflow]
	end, 'hadjustment')
		
	return scrolled_widget
end

local css_provider = gtk.CssProvider()
css_provider.load_from_string[[
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
]]

gtk.StyleContext.add_provider_for_display(
	gdk.Display.get_default(),
	css_provider,
	gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)
