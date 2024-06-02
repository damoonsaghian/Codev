if swaymsg "[workspace=__focused__ floating] focus"; then
	swaymsg "[workspace=codev floating] move scratchpad; [app_id=swapps] move scratchpad;
		[app_id=codev] move workspace codev; workspace codev"
	swaymsg "[con_id=codev] focus" || {
		python3 /usr/local/share/codev
		swaymsg '[app_id=swapps] focus' || python3 /usr/local/share/swapps.py
	}
else
	swaymsg '[app_id=swapps] focus' || python3 /usr/local/share/swapps.py
fi
