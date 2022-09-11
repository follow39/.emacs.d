 ;; (unless (featurep 'straight)
 ;;    ;; Bootstrap straight.el
 ;;    (defvar bootstrap-version)
 ;;    (let ((bootstrap-file
 ;;           (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
 ;;          (bootstrap-version 5))
 ;;      (unless (file-exists-p bootstrap-file)
 ;;        (with-current-buffer
 ;;            (url-retrieve-synchronously
 ;;           "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
 ;;             'silent 'inhibit-cookies)
 ;;          (goto-char (point-max))
 ;;          (eval-print-last-sexp)))
 ;;      (load bootstrap-file nil 'nomessage)))

 ;;  ;; Use straight.el for use-package expressions
 ;;  (straight-use-package 'use-package)
 ;;  (straight-use-package 'org)

 ;; (org-babel-load-file
 ;;  (expand-file-name
 ;;   "new_config.org"
 ;;   user-emacs-directory))
