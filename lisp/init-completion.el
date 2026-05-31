;; -*- lexical-binding: t; -*-
;; init-completion.el -- Corfu + Cape (completion), Vertico + Consult + Orderless + Marginalia + Embark

;; === In-buffer completion (like nvim-cmp) ===

(use-package corfu
  :demand t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-quit-no-match 'separator)
  (corfu-preview-current nil)
  (corfu-on-exact-match nil)
  :config
  (global-corfu-mode)
  (corfu-popupinfo-mode)
  (setq corfu-popupinfo-delay '(0.5 . 0.2)))

;; Additional completion sources (like cmp sources)
(use-package cape
  :demand t
  :config
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block))

;; Snippets (like LuaSnip + friendly-snippets)
(use-package yasnippet
  :demand t
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;; === Minibuffer completion (like Telescope) ===

;; Vertico: vertical minibuffer completion UI
(use-package vertico
  :demand t
  :config
  (setq vertico-cycle t
        vertico-count 15)
  (vertico-mode))

;; Orderless: flexible matching (like telescope fzf)
(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles partial-completion)))))

;; Marginalia: annotations in minibuffer
(use-package marginalia
  :demand t
  :config
  (marginalia-mode))

;; Consult: enhanced search commands (like telescope pickers)
(use-package consult
  :config
  (setq consult-narrow-key "<"
        consult-preview-key "M-."))

;; Embark: contextual actions (like telescope actions)
(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim))
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(provide 'init-completion)
