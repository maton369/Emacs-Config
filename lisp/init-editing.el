;; -*- lexical-binding: t; -*-
;; init-editing.el -- Surround, comment, avy, vundo, evil-mc, smartparens, subword

;; Surround (like nvim-surround)
(use-package evil-surround
  :after evil
  :demand t
  :config
  (global-evil-surround-mode 1))

;; Comment (like Comment.nvim)
(use-package evil-nerd-commenter
  :after evil
  :commands (evilnc-comment-or-uncomment-lines))

;; Avy (like flash.nvim)
(use-package avy
  :config
  (setq avy-all-windows t
        avy-background t
        avy-style 'at-full)
  ;; s for avy jump in normal mode (like flash.nvim)
  (evil-define-key 'normal 'global "s" 'avy-goto-char-2)
  (evil-define-key '(normal visual motion) 'global
    "gs" 'avy-goto-line))

;; Undo visualizer (like undotree)
(use-package vundo
  :commands vundo
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols))

;; Multi-cursor (like multicursor.nvim)
(use-package evil-mc
  :after evil
  :demand t
  :config
  (global-evil-mc-mode 1))

;; Subword mode for camelCase navigation (like nvim-spider)
(use-package subword
  :straight (:type built-in)
  :hook (prog-mode . subword-mode))

;; Smartparens for better pair handling
(use-package smartparens
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config))

;; evil-textobj-tree-sitter (like treesitter-textobjects)
(use-package evil-textobj-tree-sitter
  :after evil
  :demand t
  :config
  ;; Function text objects: af/if
  (define-key evil-outer-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.inner"))
  ;; Class text objects: ac/ic
  (define-key evil-outer-text-objects-map "c"
    (evil-textobj-tree-sitter-get-textobj "class.outer"))
  (define-key evil-inner-text-objects-map "c"
    (evil-textobj-tree-sitter-get-textobj "class.inner"))
  ;; Argument text objects: aa/ia
  (define-key evil-outer-text-objects-map "a"
    (evil-textobj-tree-sitter-get-textobj "parameter.outer"))
  (define-key evil-inner-text-objects-map "a"
    (evil-textobj-tree-sitter-get-textobj "parameter.inner")))

(provide 'init-editing)
