;; https://github.com/SebastienWae/app-launcher

;; disable fullscreen
;; send all floating to scratchpad

;; if apps menu is already activated, send all marked windows to scratchpad, and then close apps menu
;; otherwise:
;; list apps, after selection we have app's name, and exec field
;; focus all windows marked with the app's name
;; if not successful, run the exec field
;; for any new window, which its app_id is not emacs, mpv, luakit, or comacs, mark it with app's name

;swaymsg exec -- $app_exec

;; there is a list of open apps
;; when apps menu is raised, the most recent app will be selected
;; thus, pressing enter or space, always raises the last open app

;; when apps menu regains focus, it means that all windows of the last app is closed
;; so it will be removed from open apps list

; lock: /usr/local/bin/lock
; suspend: systemctl suspend
; exit: swaymsg exit
; reboot: systemctl reboot
; poweroff: systemctl poweroff
(defun sleep () (interactive)
	(call-process-shell-command "sleep 0.1; systemctl suspend")
)
(defun reboot () (interactive)
	(call-process-shell-command "systemctl reboot")
)
(defun poweroff () (interactive)
	(call-process-shell-command "systemctl poweroff")
)

;; click on minibuffer -> show apps

;; emacs-focus-marked
