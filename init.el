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
;; 		    (file-name-nondirectory (car args))))))
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
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))


;; Use no-littering to automatically set common paths to the new user-emacs-directory
(setup (:pkg no-littering)
  (require 'no-littering))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
     (if (boundp 'server-socket-dir)
         (expand-file-name "custom.el" server-socket-dir)
       (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

;; Add my library path to load-path
(push "~/.emacs.d/lisp" load-path)

(set-default-coding-systems 'utf-8)

(setup (:pkg undo-tree)
  (setq undo-tree-auto-save-history nil)
  (global-undo-tree-mode 1))

;;(server-start)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(global-set-key (kbd "C-M-u") 'universal-argument)

(setup (:pkg which-key)
  ;;(diminish 'which-key-mode)
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

(setup (:pkg general)
  ;; (general-create-definer dw/leader-key-def
  ;;   :keymaps '(normal insert visual emacs)
  ;;   :prefix "SPC"
  ;;   :global-prefix "C-SPC")

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

;; (set-frame-parameter (selected-frame) 'alpha '(99 . 99))
;; (add-to-list 'default-frame-alist '(alpha . (99 . 99)))
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

(set-face-attribute 'default nil :font "Inconsolata" :height 130)

;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil
                    :font "JetBrains Mono"
                    :weight 'light
                    :height 130)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil
                    ;; :font "Cantarell"
                    :font "Iosevka Aile"
                    :height 130
                    :weight 'light)

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

(setup (:pkg perspective)
  (:option persp-initial-frame-name "Main")
  (customize-set-variable 'persp-mode-prefix-key (kbd "C-c M-p"))
  ;; Running `persp-mode' multiple times resets the perspective list...
  (unless (equal persp-mode t)
    (persp-mode))
  )

(setup (:pkg dashboard)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-banner-logo-title "Emacs Is More Than A Text Editor!")
  (setq dashboard-startup-banner 'logo) ;; use standard emacs logo as banner
  ;;(setq dashboard-startup-banner "~/.emacs.d/emacs-dash.png")  ;; use custom image as banner
  (setq dashboard-center-content t) ;; set to 't' for centered content
  (setq dashboard-set-navigator t)
  (setq dashboard-items '((recents . 7)
                          (agenda . 5 )
                          (bookmarks . 5)
                          (projects . 10)))
  (dashboard-setup-startup-hook))

(setup (:pkg alert)
  (:option alert-default-style 'notifications))

;; (setup (:pkg super-save)
;;   (:delay)
;;   (:when-loaded
;;     (super-save-mode +1)
;;     (diminish 'super-save-mode)
;;     (setq super-save-auto-save-when-idle t)))

;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

(dw/ctrl-c-keys
  "t"  '(:ignore t :which-key "toggles")
  "tw" 'whitespace-mode
  "tt" '(counsel-load-theme :which-key "choose theme"))

(setup (:require paren)
  (set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
  (show-paren-mode 1))

(setq display-time-world-list
  '(("Etc/UTC" "UTC")
    ("Europe/Belgrade" "Belgrade")
    ("Europe/Munich" "Munich")
    ("Europe/Moscow" "Moscow")))
(setq display-time-world-time-format "%a, %d %b %H:%M %p %Z")

;;(setq epa-pinentry-mode 'loopback)
;;(pinentry-start)

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

(defun dw/show-server-edit-buffer (buffer)
  ;; TODO: Set a transient keymap to close with 'C-c C-c'
  (split-window-vertically -15)
  (other-window 1)
  (set-buffer buffer))

;; (setq server-window #'dw/show-server-edit-buffer)

(setq-default tab-width 2)

(setq-default indent-tabs-mode nil)

;; (setup (:pkg evil-nerd-commenter)
;;   (:Global "M-/" evilnc-comment-or-uncomment-lines))

(setup (:pkg ws-butler)
  (:hook-into text-mode prog-mode))

;; (setup (:pkg parinfer-rust-mode)
  ;; (:hook-into clojure-mode
              ;; emacs-lisp-mode
              ;; common-lisp-mode
              ;; scheme-mode
              ;; lisp-mode)
  ;; (setq parinfer-rust-auto-download t))

(setup (:pkg origami :guix "emacs-origami-el")
  (:hook-into yaml-mode))

(setup (:pkg hydra)
  (require 'hydra))

(setup savehist
  (setq history-length 25)
  (savehist-mode 1))

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

(setup (:pkg corfu :host github :repo "minad/corfu")
  (:with-map corfu-map
    (:bind "C-j" corfu-next
           "C-k" corfu-previous
           "TAB" corfu-insert
           "C-f" corfu-insert))
  (:option corfu-cycle t)
  (global-corfu-mode))

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
  (dw/ctrl-c-keys
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
      (bufler-defgroups
        (group
         ;; Subgroup collecting all named workspaces.
         (auto-workspace))
        (group
         ;; Subgroup collecting all `help-mode' and `info-mode' buffers.
         (group-or "*Help/Info*"
                   (mode-match "*Help*" (rx bos "help-"))
                   (mode-match "*Info*" (rx bos "info-"))))
        (group
         ;; Subgroup collecting all special buffers (i.e. ones that are not
         ;; file-backed), except `magit-status-mode' buffers (which are allowed to fall
         ;; through to other groups, so they end up grouped with their project buffers).
         (group-and "*Special*"
                    (lambda (buffer)
                      (unless (or (funcall (mode-match "Magit" (rx bos "magit-status"))
                                           buffer)
                                  (funcall (mode-match "Dired" (rx bos "dired"))
                                           buffer)
                       q           (funcall (auto-file) buffer))
                        "*Special*")))
         (group
          ;; Subgroup collecting these "special special" buffers
          ;; separately for convenience.
          (name-match "**Special**"
                      (rx bos "*" (or "Messages" "Warnings" "scratch" "Backtrace") "*")))
         (group
          ;; Subgroup collecting all other Magit buffers, grouped by directory.
          (mode-match "*Magit* (non-status)" (rx bos (or "magit" "forge") "-"))
          (auto-directory))
         ;; Subgroup for Helm buffers.
         (mode-match "*Helm*" (rx bos "helm-"))
         ;; Remaining special buffers are grouped automatically by mode.
         (auto-mode))
        ;; All buffers under "~/.emacs.d" (or wherever it is).
        (dir user-emacs-directory)
        (group
         ;; Subgroup collecting buffers in `org-directory' (or "~/org" if
         ;; `org-directory' is not yet defined).
         (dir (if (bound-and-true-p org-directory)
                  org-directory
                "~/org"))
         (group
          ;; Subgroup collecting indirect Org buffers, grouping them by file.
          ;; This is very useful when used with `org-tree-to-indirect-buffer'.
          (auto-indirect)
          (auto-file))
         ;; Group remaining buffers by whether they're file backed, then by mode.
         (group-not "*special*" (auto-file))
         (auto-mode))
        (group
         ;; Subgroup collecting buffers in a projectile project.
         (auto-projectile))
        (group
         ;; Subgroup collecting buffers in a version-control project,
         ;; grouping them by directory.
         (auto-project))
        ;; Group remaining buffers by directory, then major mode.
        (auto-directory)
        (auto-mode)))))

(setup (:pkg default-text-scale)
  (default-text-scale-mode))

(setup (:pkg ace-window)
  (:global "C-c w" ace-window)
  (:option aw-scope 'frame
           aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
           aw-minibuffer-flag t)
  (ace-window-display-mode 1))

(setup winner
  (winner-mode))

(setup (:pkg visual-fill-column :repo "https://codeberg.org/joostkremers/visual-fill-column.git")
  (:option visual-fill-column-width 110
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
              (dired-collapse-mode)))

  (add-hook 'dired-mode-hook
            (lambda ()
              (interactive)
              (dired-omit-mode 1)
              (dired-hide-details-mode 1)
              (all-the-icons-dired-mode 1)
              (hl-line-mode 1)))

  (when (eq system-type 'darwin)
    (setq insert-directory-program "/opt/homebrew/bin/gls")))

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
  (diminish org-indent-mode))

(setup (:pkg org)
;;  (:also-load org-tempo dw-org dw-workflow)
  (:also-load org-tempo dw-org)
  (:hook dw/org-mode-setup)
  (setq org-ellipsis " ▾"
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

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (scheme . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes))

(setup (:pkg org-superstar)
  (:load-after org)
  (:hook-into org-mode)
  (:option org-superstar-remove-leading-stars t
           org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))

 ;; Replace list hyphen with dot
 (font-lock-add-keywords 'org-mode
                         '(("^ *\\([-]\\) "
                            (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

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
    (add-to-list 'org-structure-template-alist '("py" . "src python"))
    (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
    (add-to-list 'org-structure-template-alist '("json" . "src json"))))

;;(require 'org-protocol)

(dw/ctrl-c-keys
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

(setup (:pkg magit :host github :repo "magit/magit")
  (:also-load magit-todos)
  (:global "C-M-;" magit-status)
  (:option magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(setup (:pkg forge)
  (:disabled))

(setup (:pkg magit-todos))

(setup (:pkg git-link)
  (setq git-link-open-in-browser t))

(setup (:pkg git-gutter :straight git-gutter-fringe)
  (:hook-into text-mode prog-mode)
  (setq git-gutter:update-interval 2)
  (require 'git-gutter-fringe)
  (set-face-foreground 'git-gutter-fr:added "LightGreen")
  (fringe-helper-define 'git-gutter-fr:added nil
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX")

  (set-face-foreground 'git-gutter-fr:modified "LightGoldenrod")
  (fringe-helper-define 'git-gutter-fr:modified nil
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX")

  (set-face-foreground 'git-gutter-fr:deleted "LightCoral")
  (fringe-helper-define 'git-gutter-fr:deleted nil
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      ".........."
      ".........."
      "XXXXXXXXXX"
      "XXXXXXXXXX"
      "XXXXXXXXXX")

  ;; These characters are used in terminal mode
  (setq git-gutter:modified-sign "≡")
  (setq git-gutter:added-sign "≡")
  (setq git-gutter:deleted-sign "≡")
  (set-face-foreground 'git-gutter:added "LightGreen")
  (set-face-foreground 'git-gutter:modified "LightGoldenrod")
  (set-face-foreground 'git-gutter:deleted "LightCoral"))

(defun dw/switch-project-action ()
  "Switch to a workspace with the project name and start `magit-status'."
  (persp-switch (projectile-project-name))
  (magit-status))

(setup (:pkg projectile)
  (when (file-directory-p "~/Documents/projects")
    (setq projectile-project-search-path '("~/Documents/projects"))
  ;; (setq projectile-switch-project-action #'dw/switch-project-action)
    (setq projectile-switch-project-action #'projectile-dired))

  (projectile-mode)

  (:global "C-c p" projectile-command-map))

(setup (:pkg lsp-mode :straight t)
  (:hook-into rustic-mode c-mode c++-mode python-mode)
  (:bind "TAB" completion-at-point)
  (:option lsp-headerline-breadcrumb-enable nil
           lsp-signature-auto-activate t
           lsp-signature-render-documentation nil
           ;; what to use when checking on-save. "check" is default, I prefer clippy
           lsp-rust-analyzer-cargo-watch-command "clippy"
           lsp-eldoc-render-all nil
           lsp-idle-delay 0.6
           ;; enable / disable the hints as you prefer:
           lsp-rust-analyzer-server-display-inlay-hints t
           lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
           lsp-rust-analyzer-display-chaining-hints t
           lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil
           lsp-rust-analyzer-display-closure-return-type-hints t
           lsp-rust-analyzer-display-parameter-hints nil
           lsp-rust-analyzer-display-reborrow-hints nil
           lsp-enable-which-key-integration t
           lsp-keymap-prefix "C-c l"))

(setup (:pkg lsp-ui :straight t)
  (:hook-into lsp-mode)
  (:option lsp-ui-peek-always-show 1
           lsp-ui-slideline-enable nil
           lsp-ui-slideline-show-hover nil
           lsp-ui-doc-enabled nil
           lsp-ui-doc-position 'bottom))

(setup (:pkg dap-mode :straight t)
  ;; Assuming that `dap-debug' will invoke all this
  (:when-loaded
    (:option lsp-enable-dap-auto-configure nil)
    (dap-ui-mode 1)
    (dap-tooltip-mode 1))

    (require 'dap-lldb)
    (require 'dap-gdb-lldb)
    ;; installs .extension/vscode
    (dap-gdb-lldb-setup)
    (dap-register-debug-template
     "Rust::LLDB Run Configuration"
     (list :type "lldb"
           :request "launch"
           :name "LLDB::Run"
           :gdbpath "rust-lldb"
           ;; uncomment if lldb-mi is not in PATH
           ;; :lldbmipath "/usr/local/bin/lldb-mi"
           )))

(setup (:pkg ccls)
  (setq ccls-executable "ccls")
  (:hook lsp)
  (:hook-into c-mode c++-mode objc-mode cuda-mode))

(setup (:pkg rustic)
  (:file-match "\\.rs\\'")
  (setq rustic-format-on-save t))

(setup emacs-lisp-mode
  (:hook flycheck-mode))

(setup (:pkg helpful)
  (:option counsel-describe-function-function #'helpful-callable
           counsel-describe-variable-function #'helpful-variable)
  (:global [remap describe-function] helpful-function
           [remap describe-symbol] helpful-symbol
           [remap describe-variable] helpful-variable
           [remap describe-command] helpful-command
           [remap describe-key] helpful-key))

(dw/ctrl-c-keys
  "e"   '(:ignore t :which-key "eval")
  "eb"  '(eval-buffer :which-key "eval buffer"))

(dw/ctrl-c-keys
  :keymaps '(visual)
  "er" '(eval-region :which-key "eval region"))

(setup (:pkg lsp-pyright :host github :repo "emacs-lsp/lsp-pyright")
  (:hook lsp)
  (:hook-into python-mode))

(setup (:pkg yaml-mode)
  (:file-match "\\.ya?ml\\'"))

(setup (:pkg flycheck)
  (:hook-into lsp-mode))

(setup (:pkg smartparens)
  (:hook-into prog-mode))

(setup (:pkg rainbow-delimiters)
  (:hook-into prog-mode))

(defun read-file (file-path)
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

(defun dw/get-current-package-version ()
  (interactive)
  (let ((package-json-file (concat (eshell/pwd) "/package.json")))
    (when (file-exists-p package-json-file)
      (let* ((package-json-contents (read-file package-json-file))
             (package-json (ignore-errors (json-parse-string package-json-contents))))
        (when package-json
          (ignore-errors (gethash "version" package-json)))))))

(defun dw/map-line-to-status-char (line)
  (cond ((string-match "^?\\? " line) "?")))

(defun dw/get-git-status-prompt ()
  (let ((status-lines (cdr (process-lines "git" "status" "--porcelain" "-b"))))
    (seq-uniq (seq-filter 'identity (mapcar 'dw/map-line-to-status-char status-lines)))))

(defun dw/get-prompt-path ()
  (let* ((current-path (eshell/pwd))
         (git-output (shell-command-to-string "git rev-parse --show-toplevel"))
         (has-path (not (string-match "^fatal" git-output))))
    (if (not has-path)
      (abbreviate-file-name current-path)
      (string-remove-prefix (file-name-directory git-output) current-path))))

;; This prompt function mostly replicates my custom zsh prompt setup
;; that is powered by github.com/denysdovhan/spaceship-prompt.
(defun dw/eshell-prompt ()
  (let ((current-branch (magit-get-current-branch))
        (package-version (dw/get-current-package-version)))
    (concat
     "\n"
     (propertize (system-name) 'face `(:foreground "#62aeed"))
     (propertize " ॐ " 'face `(:foreground "white"))
     (propertize (dw/get-prompt-path) 'face `(:foreground "#82cfd3"))
     (when current-branch
       (concat
        (propertize " • " 'face `(:foreground "white"))
        (propertize (concat " " current-branch) 'face `(:foreground "#c475f0"))))
     (when package-version
       (concat
        (propertize " @ " 'face `(:foreground "white"))
        (propertize package-version 'face `(:foreground "#e8a206"))))
     (propertize " • " 'face `(:foreground "white"))
     (propertize (format-time-string "%I:%M:%S %p") 'face `(:foreground "#5a5b7f"))
     (if (= (user-uid) 0)
         (propertize "\n#" 'face `(:foreground "red2"))
       (propertize "\nλ" 'face `(:foreground "#aece4a")))
     (propertize " " 'face `(:foreground "white")))))

(add-hook 'eshell-banner-load-hook
          (lambda ()
            (setq eshell-banner-message
                  (concat "\n" (propertize " " 'display (create-image "~/.dotfiles/.emacs.d/images/flux_banner.png" 'png nil :scale 0.2 :align-to "center")) "\n\n"))))

(defun dw/eshell-configure ()
  ;; Make sure magit is loaded
  (require 'magit)

  (setup (:pkg xterm-color))

  (push 'eshell-tramp eshell-modules-list)
  (push 'xterm-color-filter eshell-preoutput-filter-functions)
  (delq 'eshell-handle-ansi-color eshell-output-filter-functions)

  ;; Save command history when commands are entered
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

  (add-hook 'eshell-before-prompt-hook
            (lambda ()
              (setq xterm-color-preserve-properties t)))

  ;; Truncate buffer for performance
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

  ;; We want to use xterm-256color when running interactive commands
  ;; in eshell but not during other times when we might be launching
  ;; a shell command to gather its output.
  (add-hook 'eshell-pre-command-hook
            (lambda () (setenv "TERM" "xterm-256color")))
  (add-hook 'eshell-post-command-hook
            (lambda () (setenv "TERM" "dumb")))

  ;; Use completion-at-point to provide completions in eshell
  (define-key eshell-mode-map (kbd "<tab>") 'completion-at-point)

  ;; Initialize the shell history
  (eshell-hist-initialize)

  (setenv "PAGER" "cat")

  (setq eshell-prompt-function      'dw/eshell-prompt
        eshell-prompt-regexp        "^λ "
        eshell-history-size         10000
        eshell-buffer-maximum-lines 10000
        eshell-hist-ignoredups t
        eshell-highlight-prompt t
        eshell-scroll-to-bottom-on-input t
        eshell-prefer-lisp-functions nil))

(setup eshell
  (add-hook 'eshell-first-time-mode-hook #'dw/eshell-configure)
  (setq eshell-directory-name "~/.dotfiles/.emacs.d/eshell/"
        eshell-aliases-file (expand-file-name "~/.dotfiles/.emacs.d/eshell/alias")))

(setup (:pkg eshell-z)
  (:disabled) ;; Using consult-dir for this now
  (add-hook 'eshell-mode-hook (lambda () (require 'eshell-z)))
  (add-hook 'eshell-z-change-dir-hook (lambda () (eshell/pushd (eshell/pwd)))))

(setup (:pkg exec-path-from-shell)
  (setq exec-path-from-shell-check-startup-files nil)
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

(dw/ctrl-c-keys
  "SPC" 'eshell)

(with-eval-after-load 'esh-opt
  (setq eshell-destroy-buffer-when-process-dies t)
  (setq eshell-visual-commands '("htop" "zsh" "vim" "rush")))

(setup (:pkg fish-completion)
  (:disabled)
  (:hook-into eshell-mode))

(setup (:pkg eshell-syntax-highlighting)
  (:load-after eshell
    (eshell-syntax-highlighting-global-mode +1)))

(defun dw/esh-autosuggest-setup ()
  (require 'company)
  (set-face-foreground 'company-preview-common "#4b5668")
  (set-face-background 'company-preview nil))

(setup (:pkg esh-autosuggest)
  (require 'esh-autosuggest)
  (setq esh-autosuggest-delay 0.5)
  (:hook dw/esh-autosuggest-setup)
  (:hook-into eshell-mode))

(setup (:pkg eshell-toggle)
  (:disabled)
  (:global "C-M-'" eshell-toggle)
  (:option eshell-toggle-size-fraction 3
           eshell-toggle-use-projectile-root t
           eshell-toggle-run-command nil))

(setup (:pkg vterm)
  (:when-loaded
   (progn
     (setq vterm-max-scrollback 10000))))

;; Make gc pauses faster by decreasing the threshold.
(setq gc-cons-threshold (* 2 1000 1000))
