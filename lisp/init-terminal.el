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

  ;; マウスホイールで過去ログ(scrollback)をさかのぼる。
  ;;  - ライブ端末で上回転 → 自動で vterm-copy-mode に入りスクロール
  ;;  - copy-mode 中に最下部まで下回転 → 自動でライブ端末へ復帰
  ;; copy-mode 中はドラッグでの範囲選択・コピーも可能 (Claude Code の過去のやり取りを読める)。
  ;; 手動切替は従来どおり C-c C-t。
  (defun my/vterm-scrollback-up (event)
    "ライブ端末なら copy-mode に入ってからホイールで上スクロール。"
    (interactive "e")
    (unless (bound-and-true-p vterm-copy-mode)
      (vterm-copy-mode 1))
    (mwheel-scroll event))
  (defun my/vterm-scrollback-down (event)
    "copy-mode 中だけ下スクロール。最下部まで来たらライブ端末へ復帰。"
    (interactive "e")
    (when (bound-and-true-p vterm-copy-mode)
      (mwheel-scroll event)
      (when (pos-visible-in-window-p (point-max))
        (vterm-copy-mode -1))))
  (dolist (ev '([wheel-up] [double-wheel-up] [triple-wheel-up]))
    (define-key vterm-mode-map ev #'my/vterm-scrollback-up))
  (dolist (ev '([wheel-down] [double-wheel-down] [triple-wheel-down]))
    (define-key vterm-mode-map ev #'my/vterm-scrollback-down))
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
