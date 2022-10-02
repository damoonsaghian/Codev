# https://lazka.github.io/pgi-docs/#Gio-2.0/classes/AppInfo.html#Gio.AppInfo

apps = ["system", "comshell"]

apps_info = gio.AppInfo.all()

for app_info in apps_info:
  if !app_info.should_show(): continue
  apps.append(app_info.display_name())

bemenu = "bemenu --grab --bottom --margin 1 --line-height 12 --fn \"sans 10.5\""
bmenu += " --tb #4285F4 --tf #ffffff --hb #4285F4 --hf #ffffff --sb #4285F4 --sf #ffffff"
bmenu += " --fb #222222 --ff #ffffff --cb #222222 --cf #ffffff --nb #222222 --nf #ffffff"
bmenu += " --ignorecase -p applications"

app =

# if app is system, execute "system"

# if app is comshell
# "swaymsg \"workspace 1:comshell; exec comshell || python3 /usr/local/share/comshell-py/\""

# if app in not empty, and is in apps
# "swaymsg \"workspace ${app}; sway [con_id=__focused__] focus\" || swaymsg exec ${app}"

# if app in not empty, but not in apps, execute it in a shell
# create an indicator in status bar showing: in'progress, success, failure
# clear success/failure each time running swapps
