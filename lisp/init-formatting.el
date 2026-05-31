;; -*- lexical-binding: t; -*-
;; init-formatting.el -- Apheleia (format on save) + flymake-ruff

;; Apheleia: async format on save (like conform.nvim)
(use-package apheleia
  :demand t
  :config
  ;; Formatter definitions (matching conform.nvim configuration)
  ;; Most are built-in to apheleia, we just enable the mode
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-format))
  (setf (alist-get 'go-ts-mode apheleia-mode-alist) '(gofmt))
  (setf (alist-get 'rust-ts-mode apheleia-mode-alist) '(rustfmt))
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'json-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'css-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'html-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'web-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'yaml-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'markdown-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'bash-ts-mode apheleia-mode-alist) '(shfmt))

  ;; ruff-format formatter definition
  (setf (alist-get 'ruff-format apheleia-formatters)
        '("ruff" "format" "--stdin-filename" filepath "-"))

  (apheleia-global-mode t))

;; Flymake (built-in linter framework, like nvim-lint)
(use-package flymake
  :straight (:type built-in)
  :hook (prog-mode . flymake-mode)
  :config
  (setq flymake-no-changes-timeout 0.5))

;; Flymake-ruff: Python linting with ruff (like nvim-lint ruff)
(use-package flymake-ruff
  :hook (python-ts-mode . flymake-ruff-load))

(provide 'init-formatting)
