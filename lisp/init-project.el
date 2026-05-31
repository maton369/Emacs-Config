;; -*- lexical-binding: t; -*-
;; init-project.el -- project.el, desktop-save-mode, midnight, hs-minor-mode

;; Project.el (built-in project management)
(use-package project
  :straight (:type built-in)
  :config
  (setq project-switch-commands
        '((project-find-file "Find file" ?f)
          (project-find-regexp "Find regexp" ?g)
          (project-find-dir "Find directory" ?d)
          (project-vc-dir "VC dir" ?v)
          (magit-project-status "Magit" ?m))))

;; Desktop save mode (like auto-session)
(use-package desktop
  :straight (:type built-in)
  :demand t
  :config
  (setq desktop-save t
        desktop-load-locked-desktop 'check-pid
        desktop-auto-save-timeout 60
        desktop-restore-eager 5
        desktop-path (list user-emacs-directory))
  ;; Don't save certain buffers
  (add-to-list 'desktop-modes-not-to-save 'dired-mode)
  (add-to-list 'desktop-modes-not-to-save 'magit-mode)
  (add-to-list 'desktop-modes-not-to-save 'vterm-mode)
  (desktop-save-mode 1))

;; Midnight: clean up old buffers (like nvim-early-retirement)
(use-package midnight
  :straight (:type built-in)
  :demand t
  :config
  (setq clean-buffer-list-delay-general 1) ; days
  (midnight-mode 1))

;; Folding with hs-minor-mode (like nvim-ufo)
(use-package hideshow
  :straight (:type built-in)
  :hook (prog-mode . hs-minor-mode)
  :config
  ;; Evil-compatible fold keybindings
  (evil-define-key 'normal 'global
    "za" 'hs-toggle-hiding
    "zR" 'hs-show-all
    "zM" 'hs-hide-all
    "zo" 'hs-show-block
    "zc" 'hs-hide-block))

(provide 'init-project)
