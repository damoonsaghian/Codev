(menu-bar-mode -1)
(tool-bar-mode -1)
(setq inhibit-startup-screen t)
(setq use-dialog-box nil)
(setq visible-bell t)
(setq create-lockfiles nil)
(setq make-backup-files nil)
(setq auto-save-default nil)
(require 'seq)

;; new messages and upcoming schedules: send notifications to be shown in the tray area of the statusbar

;; run an emacs server to receive messages from other programs
;; create a window with class "codev"

(setq window-sides-vertical t)
(setq display-buffer-alist `(
	("\\*Completions\\*" display-buffer-pop-up-window)
	("\\*.*\\*" display-buffer-in-side-window
		(side . bottom) (slot . 0) (window-height . 0.3)
	)
))

(setq help-window-select t)

(setq window-divider-default-places t
	window-divider-default-right-width 1
	window-divider-default-bottom-width 1
)
(window-divider-mode 1)
(set-face-attribute 'window-divider nil :foreground "#aaaaaa")

;; use colored lines on top and bottom of buffers to show the amount of text above and below
;(set-face-attribute 'mode-line nil :height 1)
;(set-face-attribute 'header-line nil :height 1)

;; slightly dim unfocused panels

(setq blink-cursor-blinks 0)

(setq-default truncate-lines t)

(add-to-list 'default-frame-alist '(foreground-color . "#333333"))
;(set-face-attribute 'default nil :family "monospace" :height 105)
(set-face-attribute 'fixed-pitch-serif nil :font "monospace")
(set-face-attribute 'highlight nil :background "#CCFFFF")
(set-face-attribute 'region nil :background "#CCFFFF")
(set-face-attribute 'fringe nil :background 'unspecified)

;; never recenter point
(setq scroll-conservatively 101)
;; move point to top/bottom of buffer before signaling a scrolling error
(setq scroll-error-top-bottom t)

;; next and previous: word, line, paragraph
(defun my-previous-line () (interactive) (forward-line -1))
(defun my-next-line () (interactive) (forward-line))
(global-set-key (kbd "up") 'my-previous-line)
(global-set-key (kbd "down") 'my-next-line)
;;
(setq paragraph-start "\n" paragraph-separate "\n")
(defun my-forward-paragraph ()
	(interactive)
	(unless (bobp) (left-char))
	(forward-paragraph)
	(unless (eobp)
		(forward-paragraph)
		(redisplay t)
		(backward-paragraph)
		(right-char)))
(defun my-backward-paragraph ()
	(interactive)
	(left-char)
	(backward-paragraph)
	(unless (bobp)
		(forward-paragraph)
		(redisplay t)
		(backward-paragraph)
		(right-char)))
(global-set-key (kbd "C-up") 'my-backward-paragraph)
(global-set-key (kbd "C-down") 'my-forward-paragraph)

(cua-mode 1)
;; cua-set-mark
;; cua-set-rectangle-mark
;; cua-clear-rectangle-mark in cua--rectangle-keymap
;; backward-delete-char-untabify
(setq backward-delete-char-untabify-method 'hungry)
;; isearch-forward
;; isearch-repeat-forward in isearch-mode-map
;; completion-at-point
(cua-mode 1)
(global-set-key (kbd "C-s") 'cua-set-mark)
(global-set-key (kbd "C-a") 'cua-set-rectangle-mark)
(define-key cua--rectangle-keymap (kbd "C-a") 'cua-clear-rectangle-mark)
(global-set-key (kbd "C-d") 'backward-delete-char-untabify)
(setq backward-delete-char-untabify-method 'hungry)
(global-set-key (kbd "C-f") 'isearch-forward)
(define-key isearch-mode-map (kbd "C-f") 'isearch-repeat-forward)
(global-set-key (kbd "C-SPC") 'completion-at-point)

;; white space (space, tab, new line) + space -> tab
;; "psi" followed by two succesive apostrophes will be replaced by "ψ"
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Abbrevs.html
(defun double-space-to-tab ()
  (interactive)
  (if (and (equal (char-before (point)) ?\s)
           (not (equal (char-before (1- (point))) ?\s))
           (not (equal (char-before (1- (point))) ?\t))
           (not (equal (char-before (1- (point))) ?\n)))
      (progn (delete-backward-char 1)
             (if (equal "Find file: "
                        (buffer-substring-no-properties (point-min) (minibuffer-prompt-end)))
                 (minibuffer-complete)
               (completion-at-point)))
    (insert " ")))
(global-set-key (kbd "SPC") 'double-space-to-tab)

; elastic tab'stops:
; https://github.com/tenbillionwords/spaceship-mode
'(defun set-space-width (width)
	"Set the with of the space at point to WIDTH pixels."
	(put-text-property (point) (1+ (point))
		'display (list 'space :width (list width))
	)
)

;; store and restore undo history
;; undo all, save history, redo all, causes problems:
;; , link font lock
;; , block selection

;; clipboard handling for text, image, and "text/uri-list"
;; for the latter, ref'copy the files into the ".data" directory,
;; ask for a name, and insert the path into the text buffer

;; screen capture: https://developer.mozilla.org/en-US/docs/Web/API/Screen_Capture_API
;; to insert a screenshot or screencast:
;; move the file saved in "~/.cache/screen.png" or "~/.cache/screen.mp4" to ".data"
;; ask for a name, and insert the path into the text buffer

;; https://github.com/hrs/engine-mode
;;
(add-hook 'prog-mode-hook 'goto-address-mode)
(add-hook 'text-mode-hook 'goto-address-mode)
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/FFAP.html
(defun goto-link-at-point ()
	(interactive)
	(let ((path (ffap-file-at-point)))
		(cond
			((string-match-p "\\`git://" path)
			)
			((string-match-p "\\`https?://" path)
			)
			(t
				(message "file doesn't exist: '%s';" path)
			)
		)
	)
)

;; /method:user@host#port:filename
;; /:sudo:filename

;; orgmode
;; https://asciidoc-py.github.io/index.html
;; https://asciidoc-py.github.io/userguide.html#_tables
;; https://www.gnu.org/software/emacs/manual/html_node/ses/
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html
;; https://www.gnu.org/software/emacs/manual/html_node/org/index.html
;; https://orgmode.org/worg/

;; https://www.gnu.org/software/emacs/manual/html_mono/calc.html
;; https://www.gnu.org/software/emacs/manual//html_node/calc/Embedded-Mode.html

;; view images in a floating emacs window
;; play videos in a floating mpv window
;; view webpages in a floating luakit window

;; WYSIWYG editor for formula and 2D/3D models
;; cursor movement represents the movement inside the tree
;; eg an external program which receives formula/model as input,
;; 	shows a window for editing the formula, and at the end, outputs the formula and a generated png
;; the window can be opened at exact location of the png image
;; the window's app_id will be "comacs"
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Position-Parameters.html
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Coordinates-and-Windows.html
;; swaymsg move position <pos_x> <pos_y>
;; swaymsg resize set <width> <height>

(load "./dired.el")

;; in minibuffer press "space" -> shell

;; https://packages.debian.org/elpa-bash-completion

;; https://stackoverflow.com/questions/285660/automatically-wrapping-i-search
;; https://emacs.stackexchange.com/questions/41230/wraparound-search-with-isearch-mode
;; https://www.emacswiki.org/emacs/IncrementalSearch
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Replace.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Query-Replace.html
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Search-and-Replace.html
;; https://stackoverflow.com/questions/13095405/isearch-region-if-active-emacs

;; https://github.com/flycheck/flycheck
;; https://gitlab.com/ideasman42/emacs-spell-fu

;; voice control:
;; https://www.reddit.com/r/emacs/comments/kwb9yg/have_you_ever_used_speech_recognition_software_to/
;; http://www.cb1.com/~john/computing/emacs/handsfree/voice.html
;; https://github.com/jcaw/voicemacs
;; https://www.emacswiki.org/emacs/SpeechToText
;; https://en.wikipedia.org/wiki/Emacspeak

;; https://packages.debian.org/search?suite=stable&section=all&arch=any&searchon=names&keywords=elpa
;; https://packages.debian.org/bookworm/elpa-avy
;; https://packages.debian.org/bookworm/elpa-bm
;; https://packages.debian.org/bookworm/elpa-char-menu
;; https://packages.debian.org/bookworm/elpa-auto-complete
;; https://packages.debian.org/bookworm/elpa-auto-dictionary
;; https://packages.debian.org/bookworm/emacs-libvterm
;; https://packages.debian.org/bookworm/emacs-window-layout
;; https://packages.debian.org/bookworm/elpa-pdf-tools

;; https://emacsdocs.org/
;; https://github.com/emacs-mirror/emacs
;; https://www.emacswiki.org/emacs/ElispCookbook
;; https://www.gnu.org/software/emacs/refcards/pdf/refcard.pdf
;; https://github.com/emacs-tw/awesome-emacs
