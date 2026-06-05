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
  :hook (prog-mode . which-function-mode))

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
  "Get the working directory for startup layout.
In daemon mode, use the current frame's default-directory (set by emacsclient).
Otherwise, use the first real buffer's directory or fallback to default-directory."
  (if (daemonp)
      default-directory
    (let ((dir nil))
      (dolist (buf (buffer-list))
        (with-current-buffer buf
          (when (and (not dir)
                     (not (string-prefix-p " " (buffer-name)))
                     (not (string-prefix-p "*" (buffer-name))))
            (setq dir default-directory))))
      (or dir default-directory))))

(defun my/setup-startup-layout (&optional explicit-dir)
  "Build the startup layout: treemacs | (editor + magit) / terminal.
EXPLICIT-DIR overrides auto-detection (used by daemon hook).
Works for both local and TRAMP remote directories."
  (delete-other-windows)
  (let ((dir (or explicit-dir (my/startup-default-directory))))

    ;; 1. Treemacs on left (with correct directory)
    (when (fboundp 'treemacs)
      (let ((default-directory dir))
        (treemacs)
        ;; Add target project first, then remove others
        ;; (treemacs won't allow removing the last project)
        (treemacs-do-add-project-to-workspace
         dir (file-name-nondirectory (directory-file-name dir)))
        (let ((target (directory-file-name (file-truename dir))))
          (treemacs-block
           (dolist (proj (treemacs-workspace->projects (treemacs-current-workspace)))
             (unless (string= (directory-file-name
                               (file-truename (treemacs-project->path proj)))
                              target)
               (treemacs-do-remove-project-from-workspace proj)))))))

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

      ;; 4. Split editor right for Claude Code (if installed) or Magit
      (select-window editor-win)
      (let ((default-directory dir))
        (let ((right-win (split-window-right)))
          (with-selected-window right-win
            (if (or (executable-find "claude")
                    (file-exists-p (expand-file-name "~/.local/share/mise/installs/node/latest/bin/claude")))
                (progn
                  ;; Create magit buffer if in a git repo (accessible via H/L tab switch)
                  (ignore-errors
                    (let ((git-dir (magit-toplevel)))
                      (when git-dir (magit-status-setup-buffer git-dir))))
                  ;; Open Claude Code vterm on top
                  (vterm "claude-code")
                  (vterm-send-string "claude --verbose")
                  (vterm-send-return))
              ;; Fallback: just show Magit (only if in a git repo)
              (ignore-errors
                (let ((git-dir (magit-toplevel)))
                  (when git-dir (magit-status-setup-buffer git-dir)))))))))

    ;; 5. Focus treemacs (少し遅延させてフレーム描画後に確実にフォーカス)
    (run-with-timer 0.1 nil
      (lambda ()
        (when-let ((tw (treemacs-get-local-window)))
          (select-window tw))))))

;; Run layout on startup / new frame (daemon対応)
(if (daemonp)
    ;; デーモンモード: クライアント接続時にレイアウト構築
    ;; default-directory をフック時点で捕捉（タイマー遅延で失われるため）
    (add-hook 'server-after-make-frame-hook
              (lambda ()
                (let ((dir default-directory))
                  (run-with-timer 0.3 nil
                    (lambda ()
                      (let ((default-directory dir))
                        (my/setup-startup-layout dir)))))))
  ;; 通常モード: 起動時にレイアウト構築
  (add-hook 'emacs-startup-hook
            (lambda ()
              (run-with-timer 0.3 nil #'my/setup-startup-layout))))

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
     "a" "New file"
     "A" "New dir"
     "d" "Delete"
     "r" "Rename"
     "H" "Root up"
     "L" "Root down")
    (my/git-panel-mode
     "SPC gs" "Files"
     "RET" "Open"
     "s" "Stage"
     "u" "Unstage"
     "q" "Quit")
    (vterm-mode
     "M-o" "→Editor"
     "SPC tt" "Toggle"
     "C-\\ C-n" "Normal")
    (image-mode
     "Y" "Copy"
     "+" "Zoom in"
     "-" "Zoom out"
     "r" "Rotate"
     "n" "Next"
     "p" "Prev"))
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
  '("yy" "Copy line"
    "y" "Copy(V)"
    "p" "Paste"
    "SPC ip" "Paste img"
    "C-w v" "VSplit"
    "C-w h/j/k/l" "Move"
    "SPC g g" "Magit")
  "Global hints always shown in all buffers.")

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

;; image-mode: copy image to system clipboard
(defun my/image-copy-to-clipboard ()
  "Copy the image in the current buffer to the system clipboard."
  (interactive)
  (unless (derived-mode-p 'image-mode)
    (user-error "Not in image-mode"))
  (let ((file (expand-file-name (buffer-file-name))))
    (unless file
      (user-error "Buffer is not visiting a file"))
    (let ((exit-code
           (pcase system-type
             ('darwin
              (call-process "osascript" nil nil nil "-e"
                            (format "set the clipboard to (read (POSIX file %S) as «class PNGf»)" file)))
             ('gnu/linux
              (if (getenv "WAYLAND_DISPLAY")
                  (call-process-shell-command
                   (format "wl-copy --type image/png < %s" (shell-quote-argument file)))
                (call-process-shell-command
                 (format "xclip -selection clipboard -t image/png -i %s" (shell-quote-argument file)))))
             (_ (user-error "Unsupported OS: %s" system-type)))))
      (if (zerop exit-code)
          (message "Image copied to clipboard: %s" (file-name-nondirectory file))
        (user-error "Failed to copy image to clipboard")))))

(with-eval-after-load 'image-mode
  (define-key image-mode-map (kbd "C-c C-w") #'my/image-copy-to-clipboard))

(add-hook 'image-mode-hook
          (lambda ()
            (my/set-header-line-hints)
            (evil-local-set-key 'normal (kbd "Y") #'my/image-copy-to-clipboard)))

;; Paste clipboard image: save to ./img/ and insert link
(defun my/image-paste-from-clipboard ()
  "Save clipboard image to ./img/ and insert a link at point."
  (interactive)
  (let* ((root (or (when-let ((proj (project-current)))
                     (project-root proj))
                   default-directory))
         (dir (expand-file-name "img" root))
         (fname (format-time-string "paste-%Y%m%d-%H%M%S.png"))
         (fpath (expand-file-name fname dir)))
    (unless (file-directory-p dir)
      (make-directory dir t))
    (let ((exit-code
           (pcase system-type
             ('darwin
              (call-process "osascript" nil nil nil "-e"
                            (format "set pngData to the clipboard as «class PNGf»
set fp to open for access POSIX file %S with write permission
write pngData to fp
close access fp" fpath)))
             ('gnu/linux
              (if (getenv "WAYLAND_DISPLAY")
                  (call-process-shell-command
                   (format "wl-paste --type image/png > %s" (shell-quote-argument fpath)))
                (call-process-shell-command
                 (format "xclip -selection clipboard -t image/png -o > %s" (shell-quote-argument fpath)))))
             (_ (user-error "Unsupported OS: %s" system-type)))))
      (unless (and (zerop exit-code) (file-exists-p fpath) (> (file-attribute-size (file-attributes fpath)) 0))
        (ignore-errors (delete-file fpath))
        (user-error "No image in clipboard"))
      (let ((rel (file-relative-name fpath)))
        (cond
         ((derived-mode-p 'org-mode)
          (insert (format "[[file:%s]]" rel)))
         ((derived-mode-p 'markdown-mode)
          (insert (format "![image](%s)" rel)))
         (t
          (insert rel))))
      (message "Pasted: %s" fname))))

(provide 'init-utils)
