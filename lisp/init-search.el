;; -*- lexical-binding: t; -*-
;; init-search.el -- wgrep, consult-eglot

;; Wgrep: editable grep buffer (like spectre.nvim)
(use-package wgrep
  :config
  (setq wgrep-auto-save-buffer t
        wgrep-change-readonly-file t))

;; Consult-eglot: LSP symbols via consult (like telescope lsp pickers)
(use-package consult-eglot
  :after (consult eglot)
  :commands consult-eglot-symbols)

(provide 'init-search)
