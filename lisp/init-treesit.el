;; -*- lexical-binding: t; -*-
;; init-treesit.el -- Tree-sitter support, rainbow delimiters, context

;; Auto-install tree-sitter grammars (like nvim-treesitter ensure_installed)
(use-package treesit-auto
  :demand t
  :config
  (setq treesit-auto-install t)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Rainbow delimiters (like rainbow-delimiters.nvim)
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Topsy: sticky context header (like treesitter-context)
(use-package topsy
  :hook (prog-mode . topsy-mode))

(provide 'init-treesit)
