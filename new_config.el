;; -*- lexical-binding: t; -*-

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s seconds with %d garbage collections."
                     (emacs-init-time "%.2f")
                     gcs-done)))

;; Silence compiler warnings as they can be pretty disruptive
(setq native-comp-async-report-warnings-errors nil)

;; Set the right directory to store the native comp cache
;;(add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))

(unless (featurep 'straight)
  ;; Bootstrap straight.el
  (defvar bootstrap-version)
  (let ((bootstrap-file
         (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
        (bootstrap-version 5))
    (unless (file-exists-p bootstrap-file)
      (with-current-buffer
          (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
           'silent 'inhibit-cookies)
        (goto-char (point-max))
        (eval-print-last-sexp)))
    (load bootstrap-file nil 'nomessage)))

;; Use straight.el for use-package expressions
(straight-use-package 'use-package)

(straight-use-package '(setup :type git :host nil :repo "https://git.sr.ht/~pkal/setup"))
(require 'setup)

;; Uncomment this for debugging purposes
;; (defun dw/log-require (&rest args)
;;   (with-current-buffer (get-buffer-create "*require-log*")
;;     (insert (format "%s\n"
;;                     (file-name-nondirectory (car args))))))
;; (add-to-list 'after-load-functions #'dw/log-require)

;; Examples:
;; - (org-roam :straight t)
;; - (git-gutter :straight git-gutter-fringe)

(defun dw/filter-straight-recipe (recipe)
  (let* ((plist (cdr recipe))
         (name (plist-get plist :straight)))
    (cons (if (and name (not (equal name t)))
              name
            (car recipe))
          (plist-put plist :straight nil))))

(setup-define :pkg
  (lambda (&rest recipe)
    `(straight-use-package ',(dw/filter-straight-recipe recipe)))
  :documentation "Install RECIPE via Guix or straight.el"
  :shorthand #'cadr)

(setup-define :delay
   (lambda (&rest time)
     `(run-with-idle-timer ,(or time 1)
                           nil ;; Don't repeat
                           (lambda () (require ',(setup-get 'feature)))))
   :documentation "Delay loading the feature until a certain amount of idle time has passed.")

(setup-define :disabled
  (lambda ()
    `,(setup-quit))
  :documentation "Always stop evaluating the body.")

(setup-define :load-after
    (lambda (features &rest body)
      (let ((body `(progn
                     (require ',(setup-get 'feature))
                     ,@body)))
        (dolist (feature (if (listp features)
                             (nreverse features)
                           (list features)))
          (setq body `(with-eval-after-load ',feature ,body)))
        body))
  :documentation "Load the current feature after FEATURES."
  :indent 1)

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
;;(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
;;      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
;;(setup (:pkg no-littering)
;;  (require 'no-littering))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
;;(setq custom-file
;;      (if (boundp 'server-socket-dir)
;;          (expand-file-name "custom.el" server-socket-dir)
;;        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
;;(load custom-file t)

;; Add my library path to load-path
;;(push "~/.dotfiles/.emacs.d/lisp" load-path)

(set-default-coding-systems 'utf-8)

;;(server-start)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(global-set-key (kbd "C-M-u") 'universal-argument)

(setup (:pkg undo-tree)
  (setq undo-tree-auto-save-history nil)
  (global-undo-tree-mode 1))

(setup (:pkg evil)
  ;; Pre-load configuration
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-respect-visual-line-mode t)
  (setq evil-undo-system 'undo-tree)

  ;; Activate the Evil
  (evil-mode 1)

  ;; Set Emacs state modes
  (dolist (mode '(custom-mode
                  eshell-mode
                  git-rebase-mode
                  erc-mode
                  circe-server-mode
                  circe-chat-mode
                  circe-query-mode
                  sauron-mode
                  term-mode))
    (add-to-list 'evil-emacs-state-modes mode))

  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (defun dw/dont-arrow-me-bro ()
    (interactive)
    (message "Arrow keys are bad, you know?"))

    ;; Disable arrow keys in normal and visual modes
  (define-key evil-normal-state-map (kbd "<left>") 'dw/dont-arrow-me-bro)
  (define-key evil-normal-state-map (kbd "<right>") 'dw/dont-arrow-me-bro)
  (define-key evil-normal-state-map (kbd "<down>") 'dw/dont-arrow-me-bro)
  (define-key evil-normal-state-map (kbd "<up>") 'dw/dont-arrow-me-bro)
  (evil-global-set-key 'motion (kbd "<left>") 'dw/dont-arrow-me-bro)
  (evil-global-set-key 'motion (kbd "<right>") 'dw/dont-arrow-me-bro)
  (evil-global-set-key 'motion (kbd "<down>") 'dw/dont-arrow-me-bro)
  (evil-global-set-key 'motion (kbd "<up>") 'dw/dont-arrow-me-bro)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(setup (:pkg evil-collection)
  ;; Is this a bug in evil-collection?
  (setq evil-collection-company-use-tng nil)
  (:load-after evil
    (:option evil-collection-outline-bind-tab-p nil
             (remove evil-collection-mode-list) 'lispy
             (remove evil-collection-mode-list) 'org-present)
    (evil-collection-init)))

(setup (:pkg which-key)
  ;;(diminish 'which-key-mode)
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

(setup (:pkg general)
  (general-evil-setup t)

  (general-create-definer dw/leader-key-def
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (general-create-definer dw/ctrl-c-keys
    :prefix "C-c"))

;; Thanks, but no thanks
(setq inhibit-startup-message t)

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)       ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Set up the visible bell
(setq visible-bell t)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1) ;; keyboard scroll one line at a time
(setq use-dialog-box nil) ;; Disable dialog boxes since they weren't working in Mac OSX
(setq scroll-margin 13) ;; set scroll margin value

;;(set-frame-parameter (selected-frame) 'alpha '(95 . 95))
;;(add-to-list 'default-frame-alist '(alpha . (95 . 95)))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(column-number-mode)
(toggle-truncate-lines t)

;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
                prog-mode-hook
                conf-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 1))))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq large-file-warning-threshold nil)

(setq vc-follow-symlinks t)

(setq ad-redefinition-action 'accept)

(setup (:pkg spacegray-theme))
(setup (:pkg doom-themes))
(load-theme 'doom-palenight t)
(doom-themes-visual-bell-config)



(setup (:pkg emojify)
  (:hook erc-mode))

(setq display-time-format "%l:%M %p %b %y"
      display-time-default-load-average nil)

(setup (:pkg diminish))

;; You must run (all-the-icons-install-fonts) one time after
;; installing this package!

(setup (:pkg minions)
  (:hook-into doom-modeline-mode))

(setup (:pkg doom-modeline)
  (:hook-into after-init-hook)
  (:option doom-modeline-height 15
	   doom-modeline-bar-width 6
	   doom-modeline-lsp t
	   doom-modeline-github nil
	   doom-modeline-mu4e nil
	   doom-modeline-irc nil
	   doom-modeline-minor-modes t
	   doom-modeline-persp-name nil
	   doom-modeline-buffer-file-name-style 'truncate-except-project
	   doom-modeline-major-mode-icon nil)
  (custom-set-faces '(mode-line ((t (:height 0.85))))
		    '(mode-line-inactive ((t (:height 0.85))))))

(setup (:pkg alert)
  (:option alert-default-style 'notifications))

(setup (:pkg super-save)
  (:delay)
  (:when-loaded
    (super-save-mode +1)
    (diminish 'super-save-mode)
    (setq super-save-auto-save-when-idle t)))

;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

(dw/leader-key-def
  "t"  '(:ignore t :which-key "toggles")
  "tw" 'whitespace-mode
  "tt" '(counsel-load-theme :which-key "choose theme"))

(setup (:require paren)
  (set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
  (show-paren-mode 1))

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

(defun dw/show-server-edit-buffer (buffer)
  ;; TODO: Set a transient keymap to close with 'C-c C-c'
  (split-window-vertically -15)
  (other-window 1)
  (set-buffer buffer))

;; (setq server-window #'dw/show-server-edit-buffer)

(setq-default tab-width 2)
(setq-default evil-shift-width tab-width)

(setq-default indent-tabs-mode nil)

(setup (:pkg evil-nerd-commenter)
  (:global "M-/" evilnc-comment-or-uncomment-lines))

(setup (:pkg ws-butler)
  (:hook-into text-mode prog-mode))

(setup (:pkg parinfer :guix "emacs-parinfer-mode")
  (:disabled)
  (:hook-into clojure-mode
              emacs-lisp-mode
              common-lisp-mode
              scheme-mode
              lisp-mode)
  (setq parinfer-extensions
        '(defaults                 ; should be included.
           pretty-parens           ; different paren styles for different modes.
           evil                    ; If you use Evil.
           smart-tab               ; C-b & C-f jump positions and smart shift with tab & S-tab.
           smart-yank))            ; Yank behavior depend on mode.

  (dw/leader-key-def
    "tp" 'parinfer-toggle-mode))

(setup (:pkg origami :guix "emacs-origami-el")
  (:hook-into yaml-mode))

(setup (:pkg hydra)
  (require 'hydra))

(setup savehist
  (setq history-length 25)
  (savehist-mode 1))

;; Individual history elements can be configured separately
;;(put 'minibuffer-history 'history-length 25)
;;(put 'evil-ex-history 'history-length 50)
;;(put 'kill-ring 'history-length 25))

(defun dw/minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      ;; Borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
      (delete-word (- arg))))

(setup (:pkg vertico)
  ;; :straight '(vertico :host github
  ;;                     :repo "minad/vertico"
  ;;                     :branch "main")
  (vertico-mode)
  (:with-map vertico-map
    (:bind "C-j" vertico-next
           "C-k" vertico-previous
           "C-f" vertico-exit))
  (:with-map minibuffer-local-map
    (:bind "M-h" dw/minibuffer-backward-kill))
  (:option vertico-cycle t)
  (custom-set-faces '(vertico-current ((t (:background "#3a3f5a"))))))

(setup (:pkg orderless)
  (require 'orderless)
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles . (partial-completion))))))

(setup (:pkg consult)
  (require 'consult)
  (:global "C-s" consult-line
           "C-M-l" consult-imenu
           "C-M-j" persp-switch-to-buffer*)

  (:with-map minibuffer-local-map
    (:bind "C-r" consult-history))

  (defun dw/get-project-root ()
    (when (fboundp 'projectile-project-root)
      (projectile-project-root)))

  (:option consult-project-root-function #'dw/get-project-root
           completion-in-region-function #'consult-completion-in-region))

(setup (:pkg consult-dir :straight t)
  (:global "C-x C-d" consult-dir)
  (:with-map vertico-map
    (:bind "C-x C-d" consult-dir
           "C-x C-j" consult-dir-jump-file))
  (:option consult-dir-project-list-function nil))

;; Thanks Karthik!
(defun eshell/z (&optional regexp)
  "Navigate to a previously visited directory in eshell."
  (let ((eshell-dirs (delete-dups (mapcar 'abbreviate-file-name
                                          (ring-elements eshell-last-dir-ring)))))
    (cond
     ((and (not regexp) (featurep 'consult-dir))
      (let* ((consult-dir--source-eshell `(:name "Eshell"
                                                 :narrow ?e
                                                 :category file
                                                 :face consult-file
                                                 :items ,eshell-dirs))
             (consult-dir-sources (cons consult-dir--source-eshell consult-dir-sources)))
        (eshell/cd (substring-no-properties (consult-dir--pick "Switch directory: ")))))
     (t (eshell/cd (if regexp (eshell-find-previous-directory regexp)
                     (completing-read "cd: " eshell-dirs)))))))

(setup (:pkg marginalia)
  (:option marginalia-annotators '(marginalia-annotators-heavy
                                   marginalia-annotators-light
                                   nil))
  (marginalia-mode))

(setup (:pkg embark)
  (:also-load embark-consult)
  (:global "C-S-a" embark-act)
  (:with-map minibuffer-local-map
   (:bind "C-d" embark-act))

  ;; Show Embark actions via which-key
  (setq embark-action-indicator
        (lambda (map)
          (which-key--show-keymap "Embark" map nil nil 'no-paging)
          #'which-key--hide-popup-ignore-command)
        embark-become-indicator embark-action-indicator))

;; Binding will be set by desktop config
;;(setup (:pkg app-launcher))

(setup (:pkg avy)
  (dw/leader-key-def
    "j"   '(:ignore t :which-key "jump")
    "jj"  '(avy-goto-char :which-key "jump to char")
    "jw"  '(avy-goto-word-0 :which-key "jump to word")
    "jl"  '(avy-goto-line :which-key "jump to line")))

(setup (:pkg bufler :straight t)
  (:disabled)
  (:global "C-M-j" bufler-switch-buffer
           "C-M-k" bufler-workspace-frame-set)
  (:when-loaded
   (progn
     :config
     (evil-collection-define-key 'normal 'bufler-list-mode-map
       (kbd "RET") 'bufler-list-buffer-switch
       (kbd "M-RET") 'bufler-list-buffer-peek
       "D" 'bufler-list-buffer-kill)

     (setf bufler-groups
           (bufler-defgroups
            ;; Subgroup collecting all named workspaces.
            (group (auto-workspace))
            ;; Subgroup collecting buffers in a projectile project.
            (group (auto-projectile))
            ;; Grouping browser windows
            (group
             (group-or "Browsers"
                       (name-match "Vimb" (rx bos "vimb"))
                       (name-match "Qutebrowser" (rx bos "Qutebrowser"))
                       (name-match "Chromium" (rx bos "Chromium"))))
            (group
             (group-or "Chat"
                       (mode-match "Telega" (rx bos "telega-"))))
            (group
             ;; Subgroup collecting all `help-mode' and `info-mode' buffers.
             (group-or "Help/Info"
                       (mode-match "*Help*" (rx bos (or "help-" "helpful-")))
                       ;; (mode-match "*Helpful*" (rx bos "helpful-"))
                       (mode-match "*Info*" (rx bos "info-"))))
            (group
             ;; Subgroup collecting all special buffers (i.e. ones that are not
             ;; file-backed), except `magit-status-mode' buffers (which are allowed to fall
             ;; through to other groups, so they end up grouped with their project buffers).
             (group-and "*Special*"
                        (name-match "**Special**"
                                    (rx bos "*" (or "Messages" "Warnings" "scratch" "Backtrace" "Pinentry") "*"))
                        (lambda (buffer)
                          (unless (or (funcall (mode-match "Magit" (rx bos "magit-status"))
                                               buffer)
                                      (funcall (mode-match "Dired" (rx bos "dired"))
                                               buffer)
                                      (funcall (auto-file) buffer))
                            "*Special*"))))
            ;; Group remaining buffers by major mode.
            (auto-mode))))))

(setup (:pkg default-text-scale)
  (default-text-scale-mode))

(setup (:pkg ace-window)
  (:global "M-o" ace-window)
  (:option aw-scope 'frame
           aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
           aw-minibuffer-flag t)
  (ace-window-display-mode 1))

(setup winner
  (winner-mode)
  (define-key evil-window-map "u" 'winner-undo)
  (define-key evil-window-map "U" 'winner-redo))

(setup (:pkg visual-fill-column)
  (setq visual-fill-column-width 110
        visual-fill-column-center-text t)
  (:hook-into org-mode))

;; (setq display-buffer-base-action
;;       '(display-buffer-reuse-mode-window
;;         display-buffer-reuse-window
;;         display-buffer-same-window))

;; If a popup does happen, don't resize windows to be equal-sized
(setq even-window-sizes nil)

(setup (:pkg popper
	     :host github
	     :repo "karthink/popper"
	     :build (:not autoloads))
    (:global "C-M-;" popper-toggle-latest
	 "M-;" popper-cycle
	 "C-M-:" popper-toggle-type)
    (:option popper-window-height 12
	 popper-reference-buffers '("^\\*eshell\\*"
				    "^vterm"
				    help-mode
				    helpful-mode
				    compilation-mode))
(require 'popper) ;; Needed because I disabled autoloads
(popper-mode 1))

(setup (:pkg all-the-icons-dired))
(setup (:pkg dired-single))
(setup (:pkg dired-ranger))
(setup (:pkg dired-collapse))

(setup dired
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-omit-files "^\\.[^.].*"
        dired-omit-verbose nil
        dired-hide-details-hide-symlink-targets nil
        delete-by-moving-to-trash t)

  (autoload 'dired-omit-mode "dired-x")

  (add-hook 'dired-load-hook
            (lambda ()
              (interactive)
              (dired-collapse)))

  (add-hook 'dired-mode-hook
            (lambda ()
              (interactive)
              (dired-omit-mode 1)
              (dired-hide-details-mode 1)
              (all-the-icons-dired-mode 1)
              (hl-line-mode 1)))

  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "H" 'dired-omit-mode
    "l" 'dired-single-buffer
    "y" 'dired-ranger-copy
    "X" 'dired-ranger-move
    "p" 'dired-ranger-paste))

(setup (:pkg dired-rainbow)
  (:load-after dired
   (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
   (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
   (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
   (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
   (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
   (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
   (dired-rainbow-define media "#de751f" ("mp3" "mp4" "mkv" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
   (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
   (dired-rainbow-define log "#c17d11" ("log"))
   (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
   (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
   (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
   (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
   (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
   (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
   (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
   (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
   (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
   (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
   (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*")))

;; TODO: Mode this to another section
(setq-default fill-column 80)

;; Turn on indentation and auto-fill mode for Org files
(defun dw/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  (setq evil-auto-indent nil)
  (diminish org-indent-mode))

(setup (:pkg org)
  (:also-load org-tempo dw-org dw-workflow)
  (:hook dw/org-mode-setup)
  (setq org-ellipsis " ???"
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation nil
        org-startup-folded 'content
        org-cycle-separator-lines 2
        org-capture-bookmark nil)

  (setq org-modules
    '(org-crypt
        org-habit
        org-bookmark
        org-eshell
        org-irc))

  (setq org-refile-targets '((nil :maxlevel . 1)
                             (org-agenda-files :maxlevel . 1)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup)

  (org-babel-do-load-languages
    'org-babel-load-languages
    '((emacs-lisp . t)
      (ledger . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes))

(setup (:pkg org-superstar)
  (:load-after org)
  (:hook-into org-mode)
  (:option org-superstar-remove-leading-stars t
           org-superstar-headline-bullets-list '("???" "???" "???" "???" "???" "???" "???")))

;; Replace list hyphen with dot
;; (font-lock-add-keywords 'org-mode
;;                         '(("^ *\\([-]\\) "
;;                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "???"))))))

(setup org-faces
  ;; Make sure org-indent face is available
  (:also-load org-indent)
  (:when-loaded
    ;; Increase the size of various headings
    (set-face-attribute 'org-document-title nil :font "Iosevka Aile" :weight 'bold :height 1.3)
  
    (dolist (face '((org-level-1 . 1.2)
                    (org-level-2 . 1.1)
                    (org-level-3 . 1.05)
                    (org-level-4 . 1.0)
                    (org-level-5 . 1.1)
                    (org-level-6 . 1.1)
                    (org-level-7 . 1.1)
                    (org-level-8 . 1.1)))
      (set-face-attribute (car face) nil :font "Iosevka Aile" :weight 'medium :height (cdr face)))

    ;; Ensure that anything that should be fixed-pitch in Org files appears that way
    (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
    (set-face-attribute 'org-table nil  :inherit 'fixed-pitch)
    (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
    (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
    (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

    ;; Get rid of the background on column views
    (set-face-attribute 'org-column nil :background nil)
    (set-face-attribute 'org-column-title nil :background nil)))

;; This is needed as of Org 9.2
(setup org-tempo
  (:when-loaded
    (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
    (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
    (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
    (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
    (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
    (add-to-list 'org-structure-template-alist '("py" . "src python"))
    (add-to-list 'org-structure-template-alist '("go" . "src go"))
    (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
    (add-to-list 'org-structure-template-alist '("json" . "src json"))))

(setup (:pkg evil-org)
  (:hook-into org-mode org-agenda-mode)
  (require 'evil-org)
  (require 'evil-org-agenda)
  (evil-org-set-key-theme '(navigation todo insert textobjects additional))
  (evil-org-agenda-set-keys))

(dw/leader-key-def
  "o"   '(:ignore t :which-key "org mode")

  "oi"  '(:ignore t :which-key "insert")
  "oil" '(org-insert-link :which-key "insert link")

  "on"  '(org-toggle-narrow-to-subtree :which-key "toggle narrow")

  "os"  '(dw/counsel-rg-org-files :which-key "search notes")

  "oa"  '(org-agenda :which-key "status")
  "ot"  '(org-todo-list :which-key "todos")
  "oc"  '(org-capture t :which-key "capture")
  "ox"  '(org-export-dispatch t :which-key "export"))

(setup (:pkg org-make-toc)
  (:hook-into org-mode))

(defun dw/org-present-prepare-slide ()
  (org-overview)
  (org-show-entry)
  (org-show-children))

(defun dw/org-present-hook ()
  (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                     (header-line (:height 4.5) variable-pitch)
                                     (org-document-title (:height 1.75) org-document-title)
                                     (org-code (:height 1.55) org-code)
                                     (org-verbatim (:height 1.55) org-verbatim)
                                     (org-block (:height 1.25) org-block)
                                     (org-block-begin-line (:height 0.7) org-block)))
  (setq header-line-format " ")
  (org-appear-mode -1)
  (org-display-inline-images)
  (dw/org-present-prepare-slide)
  (dw/kill-panel))

(defun dw/org-present-quit-hook ()
  (setq-local face-remapping-alist '((default variable-pitch default)))
  (setq header-line-format nil)
  (org-present-small)
  (org-remove-inline-images)
  (org-appear-mode 1)
  (dw/start-panel))

(defun dw/org-present-prev ()
  (interactive)
  (org-present-prev)
  (dw/org-present-prepare-slide))

(defun dw/org-present-next ()
  (interactive)
  (org-present-next)
  (dw/org-present-prepare-slide)
  (when (fboundp 'live-crafter-add-timestamp)
    (live-crafter-add-timestamp (substring-no-properties (org-get-heading t t t t)))))

(setup (:pkg org-present)
  (:with-map org-present-mode-keymap
    (:bind "C-c C-j" dw/org-present-next
           "C-c C-k" dw/org-present-prev))
  (:hook dw/org-present-hook)
  (:with-hook org-present-mode-quit-hook
    (:hook dw/org-present-quit-hook)))

(defvar dw/org-roam-project-template
  '("p" "project" plain "** TODO %?"
    :if-new (file+head+olp "%<%Y%m%d%H%M%S>-${slug}.org"
                           "#+title: ${title}\n#+category: ${title}\n#+filetags: Project\n"
                           ("Tasks"))))

(defun my/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun my/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (my/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (push arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(defun dw/org-roam-goto-month ()
  (interactive)
  (org-roam-capture- :goto (when (org-roam-node-from-title-or-alias (format-time-string "%Y-%B")) '(4))
                     :node (org-roam-node-create)
                     :templates '(("m" "month" plain "\n* Goals\n\n%?* Summary\n\n"
                                   :if-new (file+head "%<%Y-%B>.org"
                                                      "#+title: %<%Y-%B>\n#+filetags: Project\n")
                                   :unnarrowed t))))

(defun dw/org-roam-goto-year ()
  (interactive)
  (org-roam-capture- :goto (when (org-roam-node-from-title-or-alias (format-time-string "%Y")) '(4))
                     :node (org-roam-node-create)
                     :templates '(("y" "year" plain "\n* Goals\n\n%?* Summary\n\n"
                                   :if-new (file+head "%<%Y>.org"
                                                      "#+title: %<%Y>\n#+filetags: Project\n")
                                   :unnarrowed t))))

(defun dw/org-roam-capture-task ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Capture the new task, creating the project file if necessary
  (org-roam-capture- :node (org-roam-node-read
                            nil
                            (my/org-roam-filter-by-tag "Project"))
                     :templates (list dw/org-roam-project-template)))

(defun my/org-roam-refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files (my/org-roam-list-notes-by-tag "Project")))

(defhydra dw/org-roam-jump-menu (:hint nil)
  "
^Dailies^        ^Capture^       ^Jump^
^^^^^^^^-------------------------------------------------
_t_: today       _T_: today       _m_: current month
_r_: tomorrow    _R_: tomorrow    _e_: current year
_y_: yesterday   _Y_: yesterday   ^ ^
_d_: date        ^ ^              ^ ^
"
  ("t" org-roam-dailies-goto-today)
  ("r" org-roam-dailies-goto-tomorrow)
  ("y" org-roam-dailies-goto-yesterday)
  ("d" org-roam-dailies-goto-date)
  ("T" org-roam-dailies-capture-today)
  ("R" org-roam-dailies-capture-tomorrow)
  ("Y" org-roam-dailies-capture-yesterday)
  ("m" dw/org-roam-goto-month)
  ("e" dw/org-roam-goto-year)
  ("c" nil "cancel"))

(setup (:pkg org-roam :straight t)
  (setq org-roam-v2-ack t)
  (setq dw/daily-note-filename "%<%Y-%m-%d>.org"
        dw/daily-note-header "#+title: %<%Y-%m-%d %a>\n\n[[roam:%<%Y-%B>]]\n\n")

  (:when-loaded
    (org-roam-db-autosync-mode)
    (my/org-roam-refresh-agenda-list))

  (:option
   org-roam-directory "~/Notes/Roam/"
   org-roam-dailies-directory "Journal/"
   org-roam-completion-everywhere t
   org-roam-capture-templates
   '(("d" "default" plain "%?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n")
      :unnarrowed t))
   org-roam-dailies-capture-templates
   `(("d" "default" entry
      "* %?"
      :if-new (file+head ,dw/daily-note-filename
                         ,dw/daily-note-header))
     ("t" "task" entry
      "* TODO %?\n  %U\n  %a\n  %i"
      :if-new (file+head+olp ,dw/daily-note-filename
                             ,dw/daily-note-header
                             ("Tasks"))
      :empty-lines 1)
     ("l" "log entry" entry
      "* %<%I:%M %p> - %?"
      :if-new (file+head+olp ,dw/daily-note-filename
                             ,dw/daily-note-header
                             ("Log")))
     ("j" "journal" entry
      "* %<%I:%M %p> - Journal  :journal:\n\n%?\n\n"
      :if-new (file+head+olp ,dw/daily-note-filename
                             ,dw/daily-note-header
                             ("Log")))
     ("m" "meeting" entry
      "* %<%I:%M %p> - %^{Meeting Title}  :meetings:\n\n%?\n\n"
      :if-new (file+head+olp ,dw/daily-note-filename
                             ,dw/daily-note-header
                             ("Log")))))
  (:global "C-c n l" org-roam-buffer-toggle
           "C-c n f" org-roam-node-find
           "C-c n d" dw/org-roam-jump-menu/body
           "C-c n c" org-roam-dailies-capture-today
           "C-c n t" dw/org-roam-capture-task
           "C-c n g" org-roam-graph)
  (:bind "C-c n i" org-roam-node-insert
         "C-c n I" org-roam-insert-immediate))

(setup (:pkg org-appear)
  (:hook-into org-mode))
