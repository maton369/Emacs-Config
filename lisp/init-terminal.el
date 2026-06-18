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
  ;; insert 状態の Esc は vterm(端末プログラム)へ送る。
  ;; これがないと evil が Esc を横取りして normal 状態に戻すだけになり、
  ;; vterm 上の Claude Code / vim 等に Esc が届かず作業中断が効かない。
  ;; vterm を抜けるのは下の M-o / C-x o を使えるので Esc を normal 復帰に使わなくてよい。
  (evil-define-key* 'insert vterm-mode-map
    (kbd "<escape>") #'vterm--self-insert)
  ;; M-o で vterm からエディタウィンドウへ即ジャンプ（ESC不要・便利キー）
  (evil-define-key* 'insert vterm-mode-map
    (kbd "M-o") (lambda () (interactive)
                  (evil-normal-state)
                  (my/focus-editor-window)))
  ;; C-x o は Emacs 標準どおり全ウィンドウを巡回させる。
  ;; (以前はエディタ窓へジャンプする実装だったため、下のターミナルや
  ;;  treemacs へ C-x o で移動できなかった。)
  (define-key vterm-mode-map (kbd "C-x o")
    (lambda () (interactive)
      (evil-normal-state)
      (other-window 1))))

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
