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
;; Go to tag: M-.
;; Dired: * m: mark file
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
 '(column-number-mode t)
 '(cua-mode t nil (cua-base))
 '(package-selected-packages
   (quote
    (matlab-mode racer company-go zenburn-theme yaml-mode web-mode scala-mode2 rust-mode processing-mode paredit lua-mode haskell-mode go-mode evil-leader elm-mode company auto-complete adoc-mode)))
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

(require 'package)
;;(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
(package-initialize)


;; Bootstrap Packages to be installed
(defvar my-packages
  '(zenburn-theme evil evil-leader company paredit perspective
                  adoc-mode yaml-mode
                  go-mode company-go
                  lua-mode web-mode  haskell-mode elm-mode matlab-mode
                  rust-mode racer company-racer
                  auctex company-auctex
                  ;;clojure-mode
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

;; Configure PATH for various packages (rust-mode, etc)
(setq exec-path (cons "~/bin" exec-path))
(setq exec-path (cons "~/.cargo/bin/" exec-path))
(setq exec-path (cons "/usr/local/go/bin" exec-path))
(add-to-list 'exec-path (expand-file-name "~/Code/go/bin"))


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
  "t"  'find-tag
  "ps" 'persp-switch
  "pc" 'persp-kill
  "pn" 'persp-next
  "pp" 'persp-prev
  "pk" 'persp-remove-buffer
  "pa" 'persp-add-buffer
  "pA" 'persp-set-buffer
  )
(global-evil-leader-mode)

;;Zenburn Theme
(load-theme 'zenburn t)

;; company-mode
(add-hook 'after-init-hook 'global-company-mode)
(setq company-backends '((company-capf company-dabbrev-code company-files)))
;; Reduce the time after which the company auto completion popup opens
(setq company-idle-delay 0.2)



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
(add-hook 'go-mode-hook 'company-mode)
(add-hook 'go-mode-hook (lambda ()
                          (setq gofmt-command "goimports")
                          (add-hook 'before-save-hook 'gofmt-before-save)

                          (set (make-local-variable 'company-backends) '(company-go))
                          (company-mode)))

;; haskell-mode
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)

;; web-mode
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.nunjucks?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jsx?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.json?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.js?\\'" . web-mode))
(add-hook 'web-mode-hook (lambda ()
                           (setq web-mode-markup-indent-offset 2)
                           (setq web-mode-code-indent-offset 2)
                           (company-mode)
                           ))

;; Customize default Javascript mode
(setq js-indent-level 2)


;; rust-mode
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
;; Set path to racer binary
(setq racer-cmd (expand-file-name "~/.cargo/bin/racer"))
(setq racer-rust-src-path (expand-file-name "~/Code/rust/rust-src/src/"))
(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'racer-mode-hook #'eldoc-mode)
(add-hook 'racer-mode-hook #'company-mode)
(setq company-tooltip-align-annotations t)
(setq rust-format-on-save t)
(setq rust-rustfmt-bin "~/.cargo/bin/rustfmt")
(add-hook 'rust-mode-hook (lambda ()
                            (company-mode)
                            (setenv "RUST_SRC_PATH" racer-rust-src-path)
                            (evil-leader/set-key
                              "." #'racer-find-definition)
                            (define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
                            ))

;; (add-hook 'rust-mode-hook
;;           (lambda ()
;;              ;; Enable racer
;;              (racer-activate)
;;              ;; Hook in racer with eldoc to provide documentation
;;              (racer-turn-on-eldoc)
;;              ;; Use flycheck-rust in rust-mode
;;              ;; (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
;;              ;; Use company-racer in rust mode
;;              (set (make-local-variable 'company-backends) '(company-racer))
;;              ;; Key binding to jump to method definition
;;              (local-set-key (kbd "M-.") #'racer-find-definition)
;;              ;; Key binding to auto complete and indent
;;              (local-set-key (kbd "TAB") #'racer-complete-or-indent)))


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'dired-find-alternate-file 'disabled nil)

;; perspective mode
(persp-mode)
