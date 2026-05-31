;; -*- lexical-binding: t; -*-
;; init-git.el -- Magit, diff-hl, blamer

;; Magit (replaces lazygit, diffview, git-worktree)
(use-package magit
  :commands (magit-status magit-log-current magit-log-buffer-file magit-log-all
             magit-diff-unstaged magit-blame magit-branch magit-worktree)
  :config
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
        magit-save-repository-buffers 'dontask))

;; Diff-hl: git gutter (like gitsigns.nvim)
(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  ;; Show in margin in terminal
  (unless (display-graphic-p)
    (diff-hl-margin-mode))
  ;; ]h / [h hunk navigation (like gitsigns.nvim)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      "]h" 'diff-hl-next-hunk
      "[h" 'diff-hl-previous-hunk)))

;; Blamer: inline git blame (like git-blame.nvim)
(use-package blamer
  :commands blamer-mode
  :config
  (setq blamer-idle-time 0.5
        blamer-min-offset 40
        blamer-type 'visual
        blamer-show-avatar-p nil
        blamer-datetime-formatter "%Y-%m-%d"
        blamer-uncommitted-changes-message "Not committed yet"))

;; --- Git diff review mode (like diffview.nvim) ---
;; SPC gv to start, ]f/[f between files, ]h/[h between hunks (cross-file), q to quit

(defvar my/git-review-files nil "List of files with git changes.")
(defvar my/git-review-index 0 "Current index in review file list.")

(defun my/git--root-dir ()
  "Get git repository root directory reliably."
  (file-name-as-directory
   (or (locate-dominating-file default-directory ".git")
       (vc-root-dir)
       default-directory)))

(defun my/git-review--changed-files ()
  "Get deduplicated list of files with git changes (staged + unstaged + untracked)."
  (let ((default-directory (my/git--root-dir)))
    (delete-dups
     (split-string
      (shell-command-to-string
       "{ git diff --name-only 2>/dev/null; git diff --name-only --cached 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u")
      "\n" t))))

(defun my/git-review--message ()
  "Show current review position."
  (message "Review [%d/%d] %s"
           (1+ my/git-review-index)
           (length my/git-review-files)
           (file-name-nondirectory (nth my/git-review-index my/git-review-files))))

(defun my/git-review--goto-file (index)
  "Open file at INDEX and jump to its first hunk."
  (setq my/git-review-index index)
  (find-file (nth index my/git-review-files))
  (goto-char (point-min))
  (ignore-errors (diff-hl-next-hunk 1))
  (my/git-review--message))

(defun my/git-review-start ()
  "Start reviewing all git changes. Navigate with ]f/[f (files) and ]h/[h (hunks)."
  (interactive)
  (let* ((root (or (vc-root-dir) default-directory))
         (files (my/git-review--changed-files)))
    (if (null files)
        (message "No git changes found.")
      (setq my/git-review-files
            (mapcar (lambda (f) (expand-file-name f root)) files)
            my/git-review-index 0)
      (my/git-review-mode 1)
      (my/git-review--goto-file 0))))

(defun my/git-review-next-file ()
  "Jump to next changed file's first hunk."
  (interactive)
  (if (>= my/git-review-index (1- (length my/git-review-files)))
      (message "Last file")
    (my/git-review--goto-file (1+ my/git-review-index))))

(defun my/git-review-prev-file ()
  "Jump to previous changed file's first hunk."
  (interactive)
  (if (<= my/git-review-index 0)
      (message "First file")
    (my/git-review--goto-file (1- my/git-review-index))))

(defun my/git-review-next-hunk ()
  "Next hunk, crossing to next file if at last hunk."
  (interactive)
  (condition-case nil
      (progn (diff-hl-next-hunk 1) (my/git-review--message))
    (error
     (if (< my/git-review-index (1- (length my/git-review-files)))
         (my/git-review--goto-file (1+ my/git-review-index))
       (message "Last hunk in last file")))))

(defun my/git-review-prev-hunk ()
  "Previous hunk, crossing to previous file if at first hunk."
  (interactive)
  (condition-case nil
      (progn (diff-hl-previous-hunk 1) (my/git-review--message))
    (error
     (if (> my/git-review-index 0)
         (progn
           (my/git-review--goto-file (1- my/git-review-index))
           (goto-char (point-max))
           (ignore-errors (diff-hl-previous-hunk 1)))
       (message "First hunk in first file")))))

(defun my/git-review-quit ()
  "Quit diff review mode."
  (interactive)
  (my/git-review-mode -1)
  (setq my/git-review-files nil my/git-review-index 0)
  (message "Review ended."))

(defvar my/git-review-mode-map (make-sparse-keymap))

(define-minor-mode my/git-review-mode
  "Navigate between files with git changes and their hunks.
\\{my/git-review-mode-map}"
  :lighter " Review"
  :global t
  :keymap my/git-review-mode-map)

(with-eval-after-load 'evil
  (evil-define-key 'normal my/git-review-mode-map
    "]f" #'my/git-review-next-file
    "[f" #'my/git-review-prev-file
    "]h" #'my/git-review-next-hunk
    "[h" #'my/git-review-prev-hunk
    "q"  #'my/git-review-quit))

;; --- Git status side panel (like neo-tree git_status source) ---
;; SPC gs to toggle. Shows only changed files grouped by status.

(defvar my/git-panel-root nil "Git root for the panel.")

(define-derived-mode my/git-panel-mode special-mode "GitPanel"
  "Side panel showing git-changed files."
  (setq buffer-read-only t
        truncate-lines t))

(defun my/git-panel--parse-status ()
  "Parse `git status --porcelain' into (staged modified untracked)."
  (let ((staged '()) (modified '()) (untracked '()))
    (dolist (line (split-string
                   (shell-command-to-string "git status --porcelain 2>/dev/null")
                   "\n" t))
      (when (>= (length line) 3)
        (let ((idx (aref line 0))
              (wt (aref line 1))
              (file (substring line 3)))
          (cond
           ((eq idx ??) (push file untracked))
           (t
            (when (memq idx '(?A ?M ?R ?D ?C))
              (push file staged))
            (when (memq wt '(?M ?D))
              (push file modified)))))))
    (list (nreverse staged) (nreverse modified) (nreverse untracked))))

(defun my/git-panel--render ()
  "Render the git status panel content."
  (let* ((default-directory my/git-panel-root)
         (status (my/git-panel--parse-status))
         (staged (nth 0 status))
         (modified (nth 1 status))
         (untracked (nth 2 status))
         (inhibit-read-only t))
    (erase-buffer)
    (insert (propertize " Git Status\n" 'face '(:weight bold :height 1.1))
            (propertize (concat " " (abbreviate-file-name my/git-panel-root) "\n\n")
                        'face '(:foreground "#6c7086")))
    (when staged
      (insert (propertize " Staged\n" 'face '(:foreground "#a6e3a1" :weight bold)))
      (dolist (f staged)
        (let ((file f))
          (insert (propertize (concat "   " file "\n")
                              'face '(:foreground "#a6e3a1")
                              'my/git-file (expand-file-name file my/git-panel-root)))))
      (insert "\n"))
    (when modified
      (insert (propertize " Modified\n" 'face '(:foreground "#f9e2af" :weight bold)))
      (dolist (f modified)
        (let ((file f))
          (insert (propertize (concat "   " file "\n")
                              'face '(:foreground "#f9e2af")
                              'my/git-file (expand-file-name file my/git-panel-root)))))
      (insert "\n"))
    (when untracked
      (insert (propertize " Untracked\n" 'face '(:foreground "#89b4fa" :weight bold)))
      (dolist (f untracked)
        (let ((file f))
          (insert (propertize (concat "   " file "\n")
                              'face '(:foreground "#89b4fa")
                              'my/git-file (expand-file-name file my/git-panel-root)))))
      (insert "\n"))
    (unless (or staged modified untracked)
      (insert (propertize "  No changes\n" 'face '(:foreground "#6c7086"))))
    (goto-char (point-min))
    (forward-line 3)))

(defun my/git-panel--editor-window ()
  "Find the main editor window (largest non-special window)."
  (let ((best nil)
        (best-area 0))
    (walk-windows
     (lambda (w)
       (let* ((buf (window-buffer w))
              (mode (buffer-local-value 'major-mode buf))
              (area (* (window-height w) (window-width w))))
         (unless (or (eq w (selected-window))
                     (memq mode '(vterm-mode treemacs-mode my/git-panel-mode))
                     (window-parameter w 'window-side))
           (when (> area best-area)
             (setq best w best-area area))))))
    best))

(defun my/git-panel-open-file ()
  "Open file at point in the editor window."
  (interactive)
  (when-let ((file (get-text-property (point) 'my/git-file)))
    (let ((win (my/git-panel--editor-window)))
      (when win (select-window win))
      (find-file file))))

(defun my/git-panel-stage ()
  "Stage file at point."
  (interactive)
  (when-let ((file (get-text-property (point) 'my/git-file)))
    (let ((default-directory my/git-panel-root))
      (shell-command (format "git add %s" (shell-quote-argument file))))
    (my/git-panel--render)
    (message "Staged: %s" (file-name-nondirectory file))))

(defun my/git-panel-unstage ()
  "Unstage file at point."
  (interactive)
  (when-let ((file (get-text-property (point) 'my/git-file)))
    (let ((default-directory my/git-panel-root))
      (shell-command (format "git reset HEAD %s" (shell-quote-argument file))))
    (my/git-panel--render)
    (message "Unstaged: %s" (file-name-nondirectory file))))

(defun my/git-panel-refresh ()
  "Refresh the git panel."
  (interactive)
  (my/git-panel--render))

(defun my/git-panel-quit ()
  "Close the git panel and restore treemacs."
  (interactive)
  (when-let ((win (get-buffer-window "*Git Status*")))
    (delete-window win))
  (kill-buffer "*Git Status*")
  (when (fboundp 'treemacs)
    (unless (treemacs-get-local-window)
      (treemacs))))

(defun my/git-panel-toggle ()
  "Toggle git status panel. Replaces treemacs; q restores it."
  (interactive)
  (if-let ((win (get-buffer-window "*Git Status*")))
      (my/git-panel-quit)
    (setq my/git-panel-root (my/git--root-dir))
    ;; Hide treemacs to make room
    (when-let ((tw (treemacs-get-local-window)))
      (delete-window tw))
    (let ((buf (get-buffer-create "*Git Status*")))
      (with-current-buffer buf
        (my/git-panel-mode)
        (my/git-panel--render))
      (let ((win (display-buffer-in-side-window buf '((side . left) (window-width . 35)))))
        (select-window win)))))

(with-eval-after-load 'evil
  (evil-define-key 'normal my/git-panel-mode-map
    (kbd "RET") #'my/git-panel-open-file
    "o"  #'my/git-panel-open-file
    "s"  #'my/git-panel-stage
    "u"  #'my/git-panel-unstage
    "r"  #'my/git-panel-refresh
    "q"  #'my/git-panel-quit))

(provide 'init-git)
