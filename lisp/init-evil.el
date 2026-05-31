;; -*- lexical-binding: t; -*-
;; init-evil.el -- Evil mode + evil-collection + general.el

;; Required before evil loads
(setq evil-want-integration t
      evil-want-keybinding nil   ; let evil-collection handle it
      evil-want-C-u-scroll t
      evil-want-Y-yank-to-eol t
      evil-undo-system 'undo-redo
      evil-split-window-below t
      evil-vsplit-window-right t)

(use-package evil
  :demand t
  :config
  ;; Move by visual line
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  ;; Move lines in visual mode (like v J/K in Neovim)
  (evil-define-key 'visual 'global
    "J" ":m '>+1\rgv=gv"
    "K" ":m '<-2\rgv=gv")

  ;; Clear search highlight with Escape
  (evil-define-key 'normal 'global (kbd "<escape>") 'evil-ex-nohighlight)

  (evil-mode 1))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (evil-collection-init))

;; general.el for leader key bindings
(use-package general
  :demand t
  :config
  (general-create-definer my/leader
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  ;; Basic leader bindings
  (my/leader
    "w" '(save-buffer :wk "Save")
    "q" '(evil-quit :wk "Quit")))

(provide 'init-evil)
