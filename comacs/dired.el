(require 'dired)
(setq dired-recursive-deletes 'always
	dired-recursive-copies 'always
	dired-keep-marker-rename nil
	dired-keep-marker-copy nil
	dired-keep-marker-hardlink nil
	dired-keep-marker-symlink nil)
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(setq dired-listing-switches "-v")
;; unfortunately "ls -v" sorting is case sensitive, even when "LC_COLLATE=en_US.UTF-8";
;; so i had to use Emacs' own "ls";
(require 'ls-lisp)
(setq ls-lisp-use-insert-directory-program nil)
(setq ls-lisp-ignore-case t)
(require 'dired-x)
(setq dired-omit-verbose nil)
(add-hook 'dired-mode-hook 'dired-omit-mode)

(define-key dired-mode-map [remap end-of-buffer]
	(lambda () (interactive)
		(end-of-buffer)
		(if (eq (point) (point-max))
			(forward-line -1)
		)
	)
)
(define-key dired-mode-map [remap forward-line]
	(lambda () (interactive)
		(forward-line 1)
		(when (eq (point) (point-max))
			(forward-char -1)
		)
	)
)
(define-key dired-mode-map [remap next-line]
	(lambda () (interactive)
		(forward-line 1)
		(when (eq (point) (point-max))
			(forward-char -1)
		)
	)
)
(define-key dired-mode-map [remap previous-line]
	(lambda () (interactive)
		(forward-line -1)
	)
)

(nconc dired-font-lock-keywords (list
	;; suffixes
	'("[^ .]\\(\\.[^. /]+\\)$" 1 dired-ignored-face)
	;; marked files
	`(,(concat "^\\([^\n " (char-to-string dired-del-marker) "].*$\\)")
		1 dired-marked-face prepend
	)
	`(,(concat "^\\([" (char-to-string dired-del-marker) "].*$\\)")
		1 dired-flagged-face prepend
	)
))

(add-hook
	'dired-after-readin-hook
	(lambda ()
		(let ((inhibit-read-only t))
			(save-excursion
				;; hide the first line in dired;
				(goto-char 1)
				(forward-line 2)
				(narrow-to-region (point) (point-max))
				(while (not (eobp))
					(let ((filename (dired-get-filename nil t)))
						(when filename
							;; hide the two spaces at the begining of each line in dired;
							(let ((ov (make-overlay (point) (1+ (point)))))
								(overlay-put ov 'invisible t)
							)
							(dired-goto-file filename)
							(let ((ov (make-overlay (1- (point)) (point))))
								(overlay-put ov 'invisible t)
							)
							(forward-line 1)
						)
					)
				)
			)
		)
	)
)

;; open directories as subtree

;; async file operations in dired
;; https://github.com/jwiegley/emacs-async
;; https://truongtx.me/tmtxt-dired-async.html
;; https://github.com/jwiegley/emacs-async/blob/master/dired-async.el

;; show thumbnails for images videos and music files

;; play audio: https://github.com/dbrock/bongo

;; archives in dired:
;; bsdtar -xf <file-path>
;; iso file: ask if you want to view its content, if not, ask for a device to write it into
;; ; sudo dd if=isofile of=devicename

;; http://pragmaticemacs.com/emacs/dired-emacs-as-a-file-browser/
;; http://pragmaticemacs.com/emacs/dired-marking-copying-moving-and-deleting-files/
;; http://pragmaticemacs.com/emacs/dired-rename-multiple-files/
;; https://stackoverflow.com/questions/2416655/file-path-to-clipboard-in-emacs
;; https://emacs.stackexchange.com/questions/17599/current-path-in-dired-or-dired-to-clipboard
;; https://emacs.stackexchange.com/questions/39116/simple-ways-to-copy-paste-files-and-directories-between-dired-buffers
;; https://stackoverflow.com/questions/20558420/how-to-go-to-a-file-quickly-in-emacs-dired
;; https://www.emacswiki.org/emacs/DiredMode
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired-and-Find.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired.html
;; https://www.gnu.org/software/emacs/refcards/pdf/dired-ref.pdf
