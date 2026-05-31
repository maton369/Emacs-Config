;; -*- lexical-binding: t; -*-
;; init-lsp.el -- Eglot (built-in LSP) + eldoc-box

;; Eglot: built-in LSP client (replaces nvim-lspconfig + mason)
(use-package eglot
  :straight (:type built-in)
  :hook ((python-ts-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (js-ts-mode . eglot-ensure)
         (json-ts-mode . eglot-ensure)
         (yaml-ts-mode . eglot-ensure)
         (html-mode . eglot-ensure)
         (css-ts-mode . eglot-ensure)
         (bash-ts-mode . eglot-ensure)
         (dockerfile-ts-mode . eglot-ensure))
  :config
  ;; Server configurations (matching Neovim's lspconfig servers)
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(go-ts-mode . ("gopls")))
  (add-to-list 'eglot-server-programs
               '(rust-ts-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(json-ts-mode . ("vscode-json-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(yaml-ts-mode . ("yaml-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((html-mode web-mode) . ("vscode-html-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(css-ts-mode . ("vscode-css-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(bash-ts-mode . ("bash-language-server" "start")))
  (add-to-list 'eglot-server-programs
               '(dockerfile-ts-mode . ("docker-langserver" "--stdio")))

  ;; Performance tuning
  (setq eglot-events-buffer-size 0         ; disable event logging
        eglot-autoshutdown t               ; shut down when last buffer closes
        eglot-sync-connect nil             ; don't block on connect
        eglot-extend-to-xref t
        eglot-report-progress nil)         ; suppress *EGLOT stderr* popups

  ;; Prevent EGLOT/Flymake log buffers from popping up
  (add-to-list 'display-buffer-alist
               '("\\*EGLOT"
                 (display-buffer-no-window)
                 (allow-no-window . t)))
  (add-to-list 'display-buffer-alist
               '("\\*Flymake log\\*"
                 (display-buffer-no-window)
                 (allow-no-window . t)))

  ;; LSP keybindings (matching Neovim's LspAttach keymaps)
  (evil-define-key 'normal eglot-mode-map
    "gd" 'xref-find-definitions        ; go to definition
    "gr" 'xref-find-references          ; find references
    "gi" 'eglot-find-implementation     ; go to implementation
    "K"  'eldoc-doc-buffer))            ; hover documentation

;; Eldoc-box: floating eldoc (like lsp_signature.nvim)
(use-package eldoc-box
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)
  :config
  (setq eldoc-box-max-pixel-width 600
        eldoc-box-max-pixel-height 400))

(provide 'init-lsp)
