;; -*- lexical-binding: t; -*-
;; init-core.el -- Basic editor settings (mirrors options.lua)

;; Line numbers
(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; Tabs and indentation
(setq-default indent-tabs-mode nil
              tab-width 2)

;; Search
(setq case-fold-search t       ; ignorecase
      isearch-lazy-count t
      lazy-count-prefix-format "(%s/%s) ")

;; Scrolling
(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t)

;; Files
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Persistent undo
(setq undo-limit 67108864        ; 64MB
      undo-strong-limit 100663296 ; 96MB
      undo-outer-limit 1006632960) ; 960MB

;; Clipboard (system clipboard sync)
(setq select-enable-clipboard t
      select-enable-primary nil)

;; Mouse
(when (display-graphic-p)
  (context-menu-mode 1))

;; Cursor line
(global-hl-line-mode 1)

;; Whitespace display (list chars)
(setq-default indicate-empty-lines t)

;; Split direction: prefer below and right
(setq split-width-threshold 160
      split-height-threshold nil)

;; Auto-revert (like autoread + checktime)
(global-auto-revert-mode 1)
(setq auto-revert-interval 1
      auto-revert-check-vc-info t
      global-auto-revert-non-file-buffers t)

;; Electric pair mode (autopairs)
(electric-pair-mode 1)

;; Delete selection on type
(delete-selection-mode 1)

;; Show matching parens
(show-paren-mode 1)
(setq show-paren-delay 0)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; Short answers (y/n instead of yes/no)
(setq use-short-answers t)

;; Don't ring the bell
(setq ring-bell-function #'ignore)

;; Remember cursor position
(save-place-mode 1)

;; Recent files
(recentf-mode 1)
(setq recentf-max-saved-items 200)

;; Save minibuffer history
(savehist-mode 1)

;; Highlight yanked text (TextYankPost equivalent)
(defun my/pulse-line (&rest _)
  "Briefly highlight the current line after yank."
  (pulse-momentary-highlight-region (mark) (point)))
(advice-add 'yank :after #'my/pulse-line)
(advice-add 'yank-pop :after #'my/pulse-line)

;; Custom file (keep init.el clean)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror))

;; Suppress noisy buffers from popping up as windows
(add-to-list 'display-buffer-alist
             '("\\*Warnings\\*"
               (display-buffer-no-window)
               (allow-no-window . t)))
(add-to-list 'display-buffer-alist
             '("\\*Async-native-compile-log\\*"
               (display-buffer-no-window)
               (allow-no-window . t)))
(add-to-list 'display-buffer-alist
             '("\\*Compile-Log\\*"
               (display-buffer-no-window)
               (allow-no-window . t)))

(provide 'init-core)
