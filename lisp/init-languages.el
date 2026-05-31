;; -*- lexical-binding: t; -*-
;; init-languages.el -- Language-specific modes

;; Go (like go.nvim)
(use-package go-mode
  :mode "\\.go\\'"
  :hook (go-ts-mode . (lambda ()
                         (setq-local tab-width 4
                                     indent-tabs-mode t))))

;; Rust (like rustaceanvim)
(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (setq rust-format-on-save nil))  ; apheleia handles formatting

;; Web mode (like nvim-ts-autotag for HTML/JSX templates)
(use-package web-mode
  :mode ("\\.html\\'" "\\.vue\\'" "\\.svelte\\'" "\\.astro\\'")
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-enable-auto-closing t
        web-mode-enable-auto-pairing t
        web-mode-enable-current-element-highlight t))

;; Emmet (like emmet-vim)
(use-package emmet-mode
  :hook ((web-mode . emmet-mode)
         (html-mode . emmet-mode)
         (css-ts-mode . emmet-mode)
         (tsx-ts-mode . emmet-mode))
  :config
  (setq emmet-move-cursor-between-quotes t))

;; YAML
(use-package yaml-mode
  :mode "\\.ya?ml\\'")

;; Markdown (like render-markdown.nvim)
(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'")
  :config
  (setq markdown-enable-math t
        markdown-fontify-code-blocks-natively t
        markdown-header-scaling t
        ;; Use Emacs built-in browser (eww) for preview — works over SSH
        markdown-command "pandoc -f markdown -t html5 --standalone"
        markdown-split-window-direction 'right))

(defun my/markdown-preview-eww ()
  "Preview Markdown in eww (Emacs built-in browser). Works in CUI/SSH."
  (interactive)
  (let ((tmp (make-temp-file "md-preview-" nil ".html")))
    (call-process-region (point-min) (point-max)
                         "pandoc" nil `(:file ,tmp) nil
                         "-f" "markdown" "-t" "html5" "--standalone")
    (eww-open-file tmp)))

;; CSV
(use-package csv-mode
  :mode "\\.csv\\'")

;; Org mode
(use-package org
  :straight (:type built-in)
  :mode ("\\.org\\'" . org-mode)
  :config
  (setq org-startup-indented t
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-src-fontify-natively t
        org-src-tab-acts-natively t))

;; Dockerfile
(use-package dockerfile-mode
  :mode "Dockerfile\\'")

;; Tailwind (like tailwind-tools.nvim)
;; Tailwind completion is handled by eglot with tailwindcss-language-server

(provide 'init-languages)
