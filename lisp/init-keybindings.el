;; -*- lexical-binding: t; -*-
;; init-keybindings.el -- All SPC-prefixed leader bindings (mirroring Neovim)

(when (fboundp 'my/leader)
(my/leader
  ;; === Find (SPC f) - like Telescope ===
  "f"  '(:ignore t :wk "Find")
  "ff" '(consult-find :wk "Find files")
  "fg" '(consult-ripgrep :wk "Live grep")
  "fb" '(consult-buffer :wk "Buffers")
  "fr" '(consult-recent-file :wk "Recent files")
  "fs" '(consult-imenu :wk "Document symbols")
  "fd" '(consult-flymake :wk "Diagnostics")
  "fk" '(describe-bindings :wk "Keymaps")
  "fh" '(describe-function :wk "Help")

  ;; === Git (SPC g) - like lazygit/gitsigns/diffview/git-worktree ===
  "g"  '(:ignore t :wk "Git")
  "gg" '(magit-status :wk "Magit status")
  "gc" '(magit-log-current :wk "Commits")
  "gb" '(magit-branch :wk "Branches")
  "gB" '(blamer-mode :wk "Toggle blame")
  "gd" '(magit-diff-unstaged :wk "Diff")
  "gf" '(magit-log-buffer-file :wk "File history")
  "gh" '(magit-log-all :wk "Repo history")
  "gw" '(magit-worktree :wk "Worktrees")
  "gs" '(my/git-panel-toggle :wk "Git status panel")
  "gr" '(diff-hl-revert-hunk :wk "Revert hunk")
  "gv" '(my/git-review-start :wk "Review changes")

  ;; === Debug (SPC d) - like nvim-dap ===
  "d"  '(:ignore t :wk "Debug")
  "dd" '(dape :wk "Start debugger")
  "db" '(dape-breakpoint-toggle :wk "Toggle breakpoint")
  "dn" '(dape-next :wk "Step over")
  "ds" '(dape-step-in :wk "Step into")
  "do" '(dape-step-out :wk "Step out")
  "dc" '(dape-continue :wk "Continue")
  "dq" '(dape-quit :wk "Quit debugger")

  ;; === Code (SPC c) - like LSP actions ===
  "c"  '(:ignore t :wk "Code")
  "ca" '(eglot-code-actions :wk "Code action")
  "cr" '(eglot-rename :wk "Rename")
  "cf" '(apheleia-format-buffer :wk "Format buffer")

  ;; === Terminal (SPC t) - like toggleterm ===
  "t"  '(:ignore t :wk "Terminal")
  "tt" '(vterm-toggle :wk "Toggle terminal")
  "tf" '((lambda () (interactive)
           (let ((vterm-toggle-fullscreen-p t))
             (vterm-toggle)))
         :wk "Terminal float")

  ;; === AI (SPC a) - like CopilotChat/avante ===
  "a"  '(:ignore t :wk "AI")
  "ac" '(gptel :wk "AI chat")
  "as" '(gptel-send :wk "AI send")

  ;; === Buffer (SPC b) ===
  "b"  '(:ignore t :wk "Buffer")
  "bd" '(kill-current-buffer :wk "Delete buffer")
  "bn" '(centaur-tabs-forward :wk "Next buffer")
  "bp" '(centaur-tabs-backward :wk "Previous buffer")

  ;; === Explorer ===
  "e"  '(treemacs :wk "Explorer")

  ;; === Undo ===
  "u"  '(vundo :wk "Undo tree")

  ;; === Zen mode ===
  "z"  '(writeroom-mode :wk "Zen mode")

  ;; === Search/Replace (SPC s) - like spectre ===
  "s"  '(:ignore t :wk "Search")
  "sr" '(consult-ripgrep :wk "Search & replace")
  "sw" '(consult-line :wk "Search word")

  ;; === Markdown / Notebook (SPC m) ===
  "m"  '(:ignore t :wk "Markdown/Notebook")
  "mp" '(my/markdown-preview-eww :wk "Markdown preview (eww)")
  "mi" '(my/jupyter-start-kernel :wk "Init kernel")
  "mk" '(jupyter-connect-repl :wk "Connect kernel")
  "mx" '(my/jupyter-eval-cell :wk "Run cell")
  "mX" '(my/jupyter-eval-cell-and-step :wk "Run+Move")
  "mc" '(my/jupyter-eval-buffer :wk "Run all cells")
  "md" '(my/jupyter-clear-all-overlays :wk "Clear outputs")))

;; === Non-leader keybindings ===

;; gd / gr / K are set in init-lsp.el
;; s (avy) is set in init-editing.el
;; H / L (tab switching) are set in init-ui.el
;; za/zR/zM (folding) are set in init-project.el
;; ]h / [h (hunk navigation) are set in init-git.el

;; gcc comment toggle (like Comment.nvim)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "gcc" 'evilnc-comment-or-uncomment-lines)
  (evil-define-key 'visual 'global
    "gc" 'evilnc-comment-or-uncomment-lines)

  ;; [d / ]d diagnostic navigation (like Neovim)
  (evil-define-key 'normal 'global
    "[d" 'flymake-goto-prev-error
    "]d" 'flymake-goto-next-error)

  ;; Window navigation with C-h/j/k/l (like smart-splits.nvim)
  (evil-define-key '(normal visual motion) 'global
    (kbd "C-h") 'evil-window-left
    (kbd "C-j") 'evil-window-down
    (kbd "C-k") 'evil-window-up
    (kbd "C-l") 'evil-window-right))

;; C-x O for reverse window switching (opposite of C-x o)
(global-set-key (kbd "C-x O") (lambda () (interactive) (other-window -1)))

(provide 'init-keybindings)
