;; statusbar:
;; https://github.com/manateelazycat/awesome-tray
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Minibuffer-Misc.html
;; https://emacs.stackexchange.com/questions/27767/center-text-in-minibuffer-echo-area
;; insert text in minibuffer using overlays:
;;   (let ((ol (make-overlay (point-min) (point-min))))
;;     (overlay-put ol 'before-string (format "%s\n" myresults)))
;; https://blog.idorobots.org/entries/system-monitor-in-emacs-mode-line.html
;; https://github.com/zk-phi/symon/blob/master/symon.el

;; cpu, memory

;; disk read and write speeds
;; https://packages.debian.org/sid/sysstat
;; https://unix.stackexchange.com/questions/55212/how-can-i-monitor-disk-io

;; backup (sync) indicator: in'progress, completed

;; system upgrade indicator: in'progress (red), system upgraded (green)
;; if upgrade failed, show an orange indicataor with exclamation mark
;; https://github.com/enkore/i3pystatus/wiki/Restart-reminder

;; battery

;; gnunet

;; internet download/upload speed, plus total rx/tx since boot
;active_net_device="$(networkctl list | grep routable | { read -r _ net_dev _; echo $net_dev; })"
;[ -n "$active_net_device" ] && {
;	read -r internet_rx < "/sys/class/net/$active_net_device/statistics/rx_bytes"
;	read -r internet_tx < "/sys/class/net/$active_net_device/statistics/tx_bytes"
;	internet_total=$(( (internet_rx + internet_tx)/100000 ))
;	
;	internet_speed=$(( (internet_total - last_internet_total) / interval ))
;	last_internet_total=$internet_total
;	
;	# if there was network activity in the last 60 seconds, set color to green
;	internet_speed_average=$(( (internet_speed + internet_speed_average*lmaf) / (lmaf+1) ))
;	[ "$internet_speed_average" = 0 ] || internet_icon_foreground_color="foreground=\"green\""
;	
;	# each 20 seconds check for online status
;	internet_online=1
;	[ "$internet_online" = 0 ] && internet_icon_foreground_color='foreground="red"'
;	
;	internet_speed="$(( internet_speed/10 )).$(( internet_speed%10 ))"
;	internet_total="$(( internet_total/10000 )).$(( (internet_total/1000)%10 ))"
;	internet="$internet_total<span $internet_icon_foreground_color>  </span>$internet_speed"
;}

;; wifi

;; cell

;; bluetooth

;; audio
;; if audio out is "Dummy Output", hide icon
;; if less that 100%, yellow icon

;; mic
;; visible only when it's active; green if volume is full, yellow otherwise
;; https://github.com/xenomachina/i3pamicstatus

;; cam: a green icon when it's active

;; screen recording indicator
;; watch for a process whose pid is in: ~/.cache/screenrec-pid

;; date'time: %Y-%m-%d %a %p %I:%M

(defun minibuffer-line-update ()
  (with-current-buffer " *Minibuf-0*"
    (erase-buffer)
    (insert (propertize (format-time-string "%F %a %I:%M%P")
                        'face '(:foreground "#777777")))))
(run-with-timer 2 2 #'minibuffer-line-update)
(global-eldoc-mode -1)
