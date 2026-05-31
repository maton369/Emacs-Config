;; -*- lexical-binding: t; -*-
;; init.el -- Bootstrap straight.el and load modules

;; Bootstrap straight.el
(defvar bootstrap-version)
(setq straight-use-package-by-default t)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install and load use-package
(straight-use-package 'use-package)
(require 'use-package)

;; Add lisp/ to load-path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Load modules in order (with error recovery)
(defun my/load-module (module)
  "Load MODULE with error handling to prevent one failure from blocking others."
  (condition-case err
      (require module)
    (error (message "Failed to load %s: %s" module (error-message-string err)))))

(mapc #'my/load-module
      '(init-core
        init-evil
        init-ui
        init-completion
        init-editing
        init-treesit
        init-lsp
        init-formatting
        init-git
        init-search
        init-project
        init-terminal
        init-languages
        init-debug
        init-notebook
        init-org
        init-ai
        init-devcontainer
        init-keybindings
        init-utils))
