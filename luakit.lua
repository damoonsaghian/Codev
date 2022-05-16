-- https://github.com/luakit/luakit/blob/develop/config/rc.lua
-- https://github.com/luakit/luakit/blob/develop/config/theme.lua
-- https://luakit.github.io/docs/
-- https://github.com/luakit/luakit/tree/develop/lib

-- https://luakit.github.io/docs/modules/luakit.unique.html
-- https://github.com/luakit/luakit/blob/develop/lib/unique_instance.lua

local instance_id = -- gained from luakit.data_dir
luakit.unique.new(instance_id)

if luakit.unique.is_running() then
  luakit.unique.send_message(uri)
  luakit.quit()
end

luakit.unique.add_signal("message", function (uri, _screen)
end)

-- send url opened in luakit to emacs

-- https://github.com/martingabelmann/luakit
-- inline PDF viewer (realized with gview-api)
webview.init_funcs.pdfview = function (view, w)
  view:add_signal("navigation-request", function (v, uri)
    if string.sub(string.lower(uri), -4) == ".pdf" then
      local url ="http://docs.google.com/gview?url="
      url = url .. uri
      url = url .. "&embedded=false"
      w:navigate(w:search_open(url))
    end
  end)
end
