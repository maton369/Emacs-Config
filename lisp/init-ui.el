;; -*- lexical-binding: t; -*-
;; init-ui.el -- Theme, modeline, dashboard, treemacs, tabs, dimmer

;; Catppuccin theme (Mocha flavor, matching Neovim)
(use-package catppuccin-theme
  :demand t
  :config
  (setq catppuccin-flavor 'mocha)
  (load-theme 'catppuccin t))

;; Doom modeline (like lualine)
(use-package doom-modeline
  :demand t
  :config
  (setq doom-modeline-height 30
        doom-modeline-bar-width 4
        doom-modeline-buffer-file-name-style 'file-name
        doom-modeline-icon t
        doom-modeline-major-mode-icon t
        doom-modeline-minor-modes nil
        doom-modeline-buffer-encoding nil
        doom-modeline-vcs-max-length 20)
  (doom-modeline-mode 1))

;; All-the-icons (required by doom-modeline and dashboard)
(use-package all-the-icons
  :if (display-graphic-p))

(use-package nerd-icons
  :demand t)

;; Dashboard (like dashboard-nvim)
(use-package dashboard
  :demand t
  :config
  (setq dashboard-banner-logo-title "Welcome to Emacs"
        dashboard-startup-banner 'logo
        dashboard-center-content t
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-items '((recents  . 8)
                          (projects . 5)
                          (bookmarks . 3))
        dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons)
  (dashboard-setup-startup-hook))

;; Treemacs (like neo-tree)
(use-package treemacs
  :commands treemacs
  :config
  (setq treemacs-width 30
        treemacs-show-hidden-files t
        treemacs-follow-after-init t
        treemacs-is-never-other-window nil)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  ;; 'extended colors both files AND directories by git status
  (treemacs-git-mode 'extended)
  ;; Git status text colors (like neo-tree git_status)
  (custom-set-faces
   '(treemacs-git-modified-face  ((t (:foreground "#f9e2af"))))  ;; yellow
   '(treemacs-git-renamed-face   ((t (:foreground "#f9e2af"))))  ;; yellow
   '(treemacs-git-added-face     ((t (:foreground "#a6e3a1"))))  ;; green
   '(treemacs-git-untracked-face ((t (:foreground "#a6e3a1"))))  ;; green
   '(treemacs-git-conflict-face  ((t (:foreground "#f38ba8"))))  ;; red
   '(treemacs-git-ignored-face   ((t (:foreground "#585b70")))))) ;; dim

(use-package treemacs-evil
  :after (treemacs evil))

;; Auto-refresh treemacs git status after magit operations (stage/unstage/commit)
(use-package treemacs-magit
  :after (treemacs magit))

;; Centaur tabs (like bufferline.nvim)
(use-package centaur-tabs
  :demand t
  :config
  (setq centaur-tabs-style "bar"
        centaur-tabs-height 32
        centaur-tabs-set-icons t
        centaur-tabs-set-modified-marker t
        centaur-tabs-modified-marker "●"
        centaur-tabs-set-bar 'under
        x-underline-at-descent-line t
        centaur-tabs-gray-out-icons 'buffer)
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match)
  ;; H/L for prev/next tab (like S-h/S-l in Neovim)
  (evil-define-key 'normal 'global
    "H" 'centaur-tabs-backward
    "L" 'centaur-tabs-forward)
  ;; Hide tabs for certain buffer types
  (setq centaur-tabs-excluded-prefixes
        '("*Messages*" "*scratch*" "*dashboard*" " *" "*Completions*")))

;; Dimmer (like tint.nvim)
(use-package dimmer
  :demand t
  :config
  (setq dimmer-fraction 0.3)
  (dimmer-configure-which-key)
  (dimmer-configure-magit)
  (dimmer-mode t))

;; Scrollbar (like nvim-scrollbar)
(use-package yascroll
  :demand t
  :config
  (global-yascroll-bar-mode 1))

(provide 'init-ui)
