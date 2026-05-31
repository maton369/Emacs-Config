;; -*- lexical-binding: t; -*-
;; init-utils.el -- which-key, hl-todo, writeroom-mode, highlight-indent-guides

;; Which-key (like which-key.nvim)
(use-package which-key
  :demand t
  :config
  (setq which-key-idle-delay 0.3
        which-key-separator " → "
        which-key-prefix-prefix "+"
        which-key-sort-order 'which-key-key-order-alpha
        which-key-max-display-columns 4)
  (which-key-mode))

;; hl-todo (like todo-comments.nvim)
(use-package hl-todo
  :demand t
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"  . "#FF8C00")
          ("FIXME" . "#FF0000")
          ("HACK"  . "#FF00FF")
          ("NOTE"  . "#00CED1")
          ("PERF"  . "#ADFF2F")
          ("WARN"  . "#FFD700")))
  (global-hl-todo-mode))

;; Writeroom-mode (like zen-mode.nvim)
(use-package writeroom-mode
  :commands writeroom-mode
  :config
  (setq writeroom-width 120
        writeroom-mode-line t
        writeroom-maximize-window nil))

;; Highlight-indent-guides (like indent-blankline.nvim)
(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :config
  (setq highlight-indent-guides-method 'character
        highlight-indent-guides-character ?\│
        highlight-indent-guides-responsive 'top))

;; Which-function-mode (like dropbar.nvim breadcrumbs)
(use-package which-func
  :straight (:type built-in)
  :demand t
  :config
  (which-function-mode 1))

;; Startup layout: treemacs | editor, terminal at bottom
(defun my/focus-editor-window ()
  "Focus the main editor window (not treemacs, not terminal)."
  (let ((editor-win nil))
    (walk-windows
     (lambda (w)
       (let ((buf (window-buffer w)))
         (unless (or (string-prefix-p "*vterm" (buffer-name buf))
                     (string-prefix-p " *Treemacs" (buffer-name buf))
                     (eq (buffer-local-value 'major-mode buf) 'treemacs-mode))
           (setq editor-win w)))))
    (when editor-win
      (select-window editor-win))))

(defun my/startup-default-directory ()
  "Get the default-directory from the first real buffer (e.g. dired from CLI arg)."
  (let ((dir nil))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (and (not dir)
                   (not (string-prefix-p " " (buffer-name)))
                   (not (string-prefix-p "*" (buffer-name))))
          (setq dir default-directory))))
    (or dir default-directory)))

(defun my/setup-startup-layout ()
  "Build the startup layout: treemacs | (editor + magit) / terminal.
Works for both local and TRAMP remote directories."
  (delete-other-windows)
  (let ((dir (my/startup-default-directory)))

    ;; 1. Treemacs on left (with correct directory)
    (when (fboundp 'treemacs)
      (let ((default-directory dir))
        (treemacs)
        ;; Remove all existing projects and add only the target
        (treemacs-block
         (dolist (proj (treemacs-workspace->projects (treemacs-current-workspace)))
           (treemacs-do-remove-project-from-workspace proj)))
        (treemacs-do-add-project-to-workspace
         dir (file-name-nondirectory (directory-file-name dir)))))

    ;; 2. Save editor window reference
    (my/focus-editor-window)
    (let ((editor-win (selected-window)))

      ;; 3. Split bottom for shared terminal
      (let ((term-height (floor (* (window-height) 0.2))))
        (split-window-below (- (window-height) term-height))
        (other-window 1)
        (when (fboundp 'vterm)
          (vterm "shell")
          (evil-normal-state)))

      ;; 4. Split editor right for Claude Code
      (select-window editor-win)
      (let ((default-directory dir))
        (let ((right-win (split-window-right)))
          (with-selected-window right-win
            ;; Create magit buffer (accessible via H/L tab switch)
            (magit-status-setup-buffer (or (magit-toplevel) dir))
            ;; Open Claude Code vterm on top
            (vterm "claude-code")
            (vterm-send-string "claude")
            (vterm-send-return)))))

    ;; 5. Focus treemacs
    (when-let ((tw (treemacs-get-local-window)))
      (select-window tw))))

;; Run layout AFTER dashboard finishes (dashboard uses emacs-startup-hook too)
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 0.3 nil #'my/setup-startup-layout)))

;; Context-aware keybinding hints in header-line
(defvar my/mode-hints
  '((markdown-mode
     "SPC mp" "Preview(eww)"
     "C-c C-s" "Style"
     "C-c C-l" "Link"
     "C-c C-i" "Image")
    (python-ts-mode
     "SPC dd" "Debug"
     "SPC ca" "Action"
     "SPC cf" "Format"
     "SPC fd" "Diag")
    (python-mode
     "SPC dd" "Debug"
     "SPC ca" "Action"
     "SPC cf" "Format"
     "SPC fd" "Diag")
    (go-ts-mode
     "SPC dd" "Debug"
     "SPC ca" "Action"
     "SPC cf" "Format"
     "gd" "Def")
    (rust-ts-mode
     "SPC ca" "Action"
     "SPC cf" "Format"
     "gd" "Def"
     "K" "Hover")
    (typescript-ts-mode
     "SPC ca" "Action"
     "SPC cf" "Format"
     "gd" "Def"
     "gr" "Refs")
    (tsx-ts-mode
     "SPC ca" "Action"
     "SPC cf" "Format"
     "gd" "Def"
     "gr" "Refs")
    (js-ts-mode
     "SPC ca" "Action"
     "SPC cf" "Format"
     "gd" "Def"
     "gr" "Refs")
    (org-mode
     "C-c C-x C-l" "LaTeX"
     "C-c C-," "Cite"
     "C-c C-e" "Export"
     "C-c C-t" "TODO"
     "C-c C-s" "Schedule"
     "C-c '" "Edit src")
    (latex-mode
     "C-c C-c" "Compile"
     "C-c C-v" "View"
     "`" "Math"
     "C-c C-e" "Env")
    (magit-status-mode
     "TAB" "Toggle"
     "s" "Stage"
     "u" "Unstage"
     "c c" "Commit"
     "P p" "Push"
     "F p" "Pull"
     "l l" "Log"
     "b b" "Branch"
     "r i" "Rebase"
     "g" "Refresh"
     "q" "Quit"
     "?" "Help")
    (dape-info-mode
     "n" "Next"
     "s" "Step in"
     "o" "Step out"
     "c" "Continue")
    (treemacs-mode
     "SPC gs" "Git status"
     "SPC e" "Toggle"
     "C-l" "Editor"
     "?" "Help")
    (my/git-panel-mode
     "SPC gs" "Files"
     "RET" "Open"
     "s" "Stage"
     "u" "Unstage"
     "q" "Quit")
    (vterm-mode
     "SPC tt" "Toggle"
     "C-\\ C-n" "Normal"
     "C-h/k" "Window"))
  "Alist of (MAJOR-MODE KEY1 DESC1 KEY2 DESC2 ...) for header-line hints.")

(defvar my/file-hints
  '(("COMMIT_EDITMSG"
     "C-c C-c" "Finish"
     "C-c C-k" "Abort")
    ("\\.ipynb\\'"
     "SPC mx" "Run cell"
     "SPC mc" "Run all"
     "SPC mp" "Plot setup"
     "SPC mi" "Init kernel")
    ("\\.tex\\'"
     "C-x C-s" "Compile→PDF"
     "C-c C-e" "Env"
     "`" "Math"))
  "Alist of (FILE-REGEXP KEY1 DESC1 KEY2 DESC2 ...) for header-line hints.")

(defvar my/global-hints
  '("C-x →" "Next buf"
    "C-x ←" "Prev buf"
    "C-w v" "VSplit"
    "C-w s" "HSplit"
    "C-w h/j/k/l" "Move"
    "C-w q" "Close"
    "SPC g g" "Magit")
  "Window hints always shown in all buffers.")

(defun my/get-context-hints ()
  "Get keybinding hints for the current mode/file.
File-name patterns take priority over major-mode hints.
Global window hints are always appended."
  (let ((hints nil))
    (when buffer-file-name
      (let ((entries my/file-hints))
        (while (and entries (not hints))
          (when (string-match-p (caar entries) buffer-file-name)
            (setq hints (cdar entries)))
          (setq entries (cdr entries)))))
    (unless hints
      (setq hints (cdr (assq major-mode my/mode-hints))))
    (append hints my/global-hints)))

(defun my/format-hints (hints)
  "Format HINTS list into a display string."
  (when hints
    (let ((parts nil)
          (h (copy-sequence hints)))
      (while h
        (let ((key (pop h))
              (desc (pop h)))
          (push (concat
                 (propertize (concat " " key " ") 'face '(:background "#45475a" :foreground "#cdd6f4" :weight bold))
                 (propertize (concat " " desc) 'face '(:foreground "#a6adc8"))
                 " ")
                parts)))
      (string-join (nreverse parts)))))

;; doom-modeline segment for context hints (editor windows)
(with-eval-after-load 'doom-modeline
  (doom-modeline-def-segment context-hints
    "Show context-aware keybinding hints."
    (my/format-hints (my/get-context-hints)))

  ;; Add to the default mode-line
  (doom-modeline-def-modeline 'main
    '(bar workspace-name window-number modals matches follow remote-host buffer-position word-count parrot selection-info)
    '(context-hints misc-info minor-modes input-method indent-info buffer-encoding major-mode process vcs check)))

;; header-line hints for special modes (treemacs, git-panel, vterm etc.)
(defun my/set-header-line-hints ()
  "Set header-line-format with context hints for current mode."
  (when-let ((hints (my/get-context-hints)))
    (setq header-line-format (my/format-hints hints))))

(add-hook 'treemacs-mode-hook #'my/set-header-line-hints)
(add-hook 'my/git-panel-mode-hook #'my/set-header-line-hints)
(add-hook 'vterm-mode-hook #'my/set-header-line-hints)
(add-hook 'magit-status-mode-hook #'my/set-header-line-hints)
(add-hook 'git-commit-mode-hook #'my/set-header-line-hints)

(provide 'init-utils)
