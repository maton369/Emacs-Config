;; -*- lexical-binding: t; -*-
;; init-terminal.el -- vterm + vterm-toggle

;; Vterm (like toggleterm.nvim)
(use-package vterm
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000
        vterm-timer-delay 0.01)
  ;; C-h/j/k/l でターミナルから直接ウィンドウ移動（Neovim と同じ）
  (evil-define-key 'insert vterm-mode-map
    (kbd "C-\\ C-n") 'vterm-send-escape
    (kbd "C-h") #'evil-window-left
    (kbd "C-j") #'evil-window-down
    (kbd "C-k") #'evil-window-up
    (kbd "C-l") #'evil-window-right))

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
