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

;; --- CUI で TUI アプリ(Claude Code 等)を崩さないための vterm 衛生設定 ---
(defun my/vterm-tui-hygiene ()
  "Make vterm safe for full-screen TUIs in the terminal."
  ;; 入力枠を最下行に固定し、前回位置を保持しない
  (setq-local scroll-margin 0
              scroll-conservatively 101
              scroll-preserve-screen-position nil
              vterm-max-scrollback 5000)
  ;; header-line は vterm では出さない(ヒントはモードライン側に出る)
  (setq-local header-line-format nil)
  ;; グローバル装飾を vterm 内では無効化(軽量化・描画の乱れ防止)
  (when (bound-and-true-p global-hl-line-mode) (setq-local global-hl-line-mode nil))
  (hl-line-mode -1)
  (display-line-numbers-mode -1)
  (when (fboundp 'yascroll-bar-mode) (yascroll-bar-mode -1))
  (buffer-face-mode -1)
  ;; カーソルを箱型固定・伸縮無効・点滅停止でセル位置に一致させる
  (setq-local cursor-type 'box
              x-stretch-cursor nil)
  (when (bound-and-true-p blink-cursor-mode) (blink-cursor-mode -1))
  ;; CUI(TTY)でのみ tab-line(centaur-tabs)を除去する。
  ;; 最上行を1行奪うと vterm のカーソル行が1行ずれるため。
  ;; GUI はピクセル単位で描画されずれないので、タブはそのまま残す。
  (unless (display-graphic-p)
    (setq-local tab-line-format nil)
    (when (fboundp 'centaur-tabs-local-mode) (centaur-tabs-local-mode 1))))
(add-hook 'vterm-mode-hook #'my/vterm-tui-hygiene)

(provide 'init-terminal)
