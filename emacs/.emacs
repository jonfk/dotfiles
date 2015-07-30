(setq inhibit-startup-screen t)
(setq inhibit-splash-screen t)
;;(setq-default truncate-lines t)
(setq visible-bell t)
(require 'cl)

(setq scroll-step            1
      scroll-conservatively  10000)

;; Custom message in the scratch buffer
(setq initial-scratch-message
      ";; This buffer is for notes you don't want to save, and for Lisp evaluation.
;; Help: C-h m(mode info), C-h b(buffer info), C-h ?(help menu)
;; Create File: C-x C-f
;; Exit: C-x C-c
;; Comment Region: M-;
;; Indent Region: C-M-\
;; Close other/this window: C-x 0 or C-x 1
;; Go to buffer: C-x b
;; Kill Buffer: C-x k
;; ISearch: C-s
")


;; Start server unless it has already started
(load "server")
(unless (server-running-p) (server-start))

;; Save emacs backups into .emacs_saves
(setq backup-directory-alist `(("." . "~/.emacs_saves")))

;; Prevent Tabs
(setq-default indent-tabs-mode nil)

;; turn on font-lock mode
(global-font-lock-mode t)

;; enable visual feedback on selections
(setq-default transient-mark-mode t)

;; Show and strip trailing whitespace on write
(setq-default show-trailing-whitespace t)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.

 ;; Show column number (This will show both line and column in '()')
 '(column-number-mode t)
 '(cua-mode t nil (cua-base))
 '(show-paren-mode t)
 '(tool-bar-mode nil))

;; C and Java indentation
(setq c-default-style "linux" c-basic-offset 4) ;;for C indent and braces
(setq c-basic-offset 4) ;;for java indent only

;; Prompt before closing emacs in GUI mode
(defun ask-before-closing ()
  "Ask whether or not to close, and then close if y was pressed"
  (interactive)
  (if (y-or-n-p (format "Are you sure you want to exit Emacs? "))
      (if (< emacs-major-version 22)
          (save-buffers-kill-terminal)
        (save-buffers-kill-emacs))
    (message "Canceled exit")))

(when window-system
  (global-set-key (kbd "C-x C-c") 'ask-before-closing))

;; Marmelade Package Repository
(require 'package)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
(package-initialize)


;; Bootstrap Packages to be installed
(defvar my-packages
  '(zenburn-theme evil evil-leader auto-complete company go-mode paredit haskell-mode elm-mode
                  adoc-mode lua-mode web-mode
                  ;;auctex clojure-mode
		  ;;magit paredit projectile volatile-highlights minimap
                  ;;rainbow-mode deft
		  )
  "A list of packages to ensure are installed at launch.")

(defun my-packages-installed-p ()
  (loop for p in my-packages
	when (not (package-installed-p p)) do (return nil)
	finally (return t)))

(unless (my-packages-installed-p)
  ;; check for new packages (package versions)
  (message "%s" "Emacs Prelude is now refreshing its package database...")
  (package-refresh-contents)
  (message "%s" " done.")
  ;; install the missing packages
  (dolist (p my-packages)
    (when (not (package-installed-p p))
      (package-install p))))

(provide 'my-packages)

;; Configuration for Packages
;; Add elpa packages to load-path
(add-to-list 'load-path "~/.emacs.d/elpa/")

;; Evil
(require 'evil)
(evil-mode 1)

;;Evil Leader
(require 'evil-leader)
(evil-leader/set-leader ",")
(evil-leader/set-key
  "ev" '(lambda () (interactive)(find-file "~/.emacs"))
  "so" '(lambda () (interactive) (eval-buffer))
  "xc" 'ask-before-closing
  "f"  'find-file
  "b"  'switch-to-buffer
  "k"  'kill-buffer
  "\\" 'indent-region
  )
(global-evil-leader-mode)

;;Zenburn Theme
(load-theme 'zenburn t)

;; Auto-complete
(require 'auto-complete)
(global-auto-complete-mode t)


;; Comment and uncomment region or line
(defun comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

;; Custom Keybinds

;; Language Specific

;; go-mode
(setq exec-path (cons "/usr/local/go/bin" exec-path))
(add-to-list 'exec-path "/home/jon/Code/go/bin")
(add-hook 'before-save-hook 'gofmt-before-save)

;; haskell-mode
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)
