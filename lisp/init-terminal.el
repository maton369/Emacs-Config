;; -*- lexical-binding: t; -*-
;; init-terminal.el -- vterm + vterm-toggle

;; Vterm (like toggleterm.nvim)
(use-package vterm
  :commands vterm
  :init
  (setq vterm-always-compile-module t)
  :config
  (setq vterm-max-scrollback 10000
        vterm-timer-delay 0.01)
  ;; M-o で vterm からエディタウィンドウへ移動（ESC不要）
  (evil-define-key* 'insert vterm-mode-map
    (kbd "M-o") (lambda () (interactive)
                  (evil-normal-state)
                  (my/focus-editor-window)))
  ;; C-x o も残す（Emacs標準キー）
  (define-key vterm-mode-map (kbd "C-x o")
    (lambda () (interactive)
      (evil-normal-state)
      (my/focus-editor-window))))

;; Vterm-toggle (like toggleterm toggle behavior)
(use-package vterm-toggle
  :commands (vterm-toggle vterm-toggle-cd)
  :config
  (setq vterm-toggle-scope 'project
        vterm-toggle-fullscreen-p nil)
  ;; Show vterm at bottom (like toggleterm horizontal)
  (setq vterm-toggle-hide-method 'reset-window-configration)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                   (let ((buffer (get-buffer buffer-or-name)))
                     (when buffer
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name
                                              (buffer-name buffer)))))))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (reusable-frames . visible)
                 (window-height . 0.3))))

(provide 'init-terminal)
