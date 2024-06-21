--[[
https://stackoverflow.com/questions/23433819/creating-a-simple-file-browser-using-python-and-gtktreeview
https://github.com/tchx84/Portfolio
http://zetcode.com/gui/pygtk/advancedwidgets/
https://github.com/MeanEYE/Sunflower
https://gitlab.xfce.org/apps/catfish/
https://gitlab.gnome.org/aviwad/organizer

https://github.com/donadigo/elementary-ide

archives:
bsdtar -xf <file-path>

.iso file: ask if user wants to extract it, if not, ask for a device to write it into, then:
; sudo dd if=isofile of=devicename
]]

Files = gtk.Listbox:extend(function (project_directory)
end)
	
function Files:move_up()
end

function Files:move_down()
end

function Files:go_to_file()
end

function Files:find_file()
end
