;; -*- lexical-binding: t; -*-
;; verify-packages.el -- 全パッケージのインストール状態を確認
;;
;; 使い方:
;;   M-x load-file RET ~/.emacs.d/lisp/verify-packages.el RET
;;   または Emacs 起動後: M-x verify-packages

(defvar my/expected-packages
  '(;; init-evil.el
    (evil           "Vim emulation"               "init-evil")
    (evil-collection "Evil bindings for many modes" "init-evil")
    (general        "Leader key framework"         "init-evil")

    ;; init-ui.el
    (catppuccin-theme "Catppuccin color theme"     "init-ui")
    (doom-modeline  "Modeline (like lualine)"      "init-ui")
    (all-the-icons  "Icon font support"            "init-ui")
    (nerd-icons     "Nerd font icons"              "init-ui")
    (dashboard      "Startup dashboard"            "init-ui")
    (treemacs       "File explorer (like neo-tree)" "init-ui")
    (treemacs-evil  "Evil bindings for treemacs"   "init-ui")
    (centaur-tabs   "Buffer tabs (like bufferline)" "init-ui")
    (dimmer         "Dim inactive windows"         "init-ui")
    (yascroll       "Scrollbar"                    "init-ui")

    ;; init-completion.el
    (corfu          "In-buffer completion (like nvim-cmp)" "init-completion")
    (cape           "Completion sources"           "init-completion")
    (yasnippet      "Snippet engine (like LuaSnip)" "init-completion")
    (yasnippet-snippets "Snippet collection"       "init-completion")
    (vertico        "Minibuffer UI (like telescope)" "init-completion")
    (orderless      "Fuzzy matching"               "init-completion")
    (marginalia     "Minibuffer annotations"       "init-completion")
    (consult        "Search commands (like telescope pickers)" "init-completion")
    (embark         "Contextual actions"           "init-completion")
    (embark-consult "Embark + Consult integration" "init-completion")

    ;; init-editing.el
    (evil-surround  "Surround editing (like nvim-surround)" "init-editing")
    (evil-nerd-commenter "Comment toggle (like Comment.nvim)" "init-editing")
    (avy            "Jump navigation (like flash.nvim)" "init-editing")
    (vundo          "Undo tree (like undotree)"    "init-editing")
    (evil-mc        "Multi-cursor (like multicursor.nvim)" "init-editing")
    (smartparens    "Smart pair handling"           "init-editing")
    (evil-textobj-tree-sitter "Treesitter text objects" "init-editing")

    ;; init-treesit.el
    (treesit-auto   "Auto-install tree-sitter grammars" "init-treesit")
    (rainbow-delimiters "Rainbow parentheses"      "init-treesit")
    (topsy          "Sticky context (like treesitter-context)" "init-treesit")

    ;; init-lsp.el
    (eldoc-box      "Floating eldoc (like lsp_signature)" "init-lsp")

    ;; init-formatting.el
    (apheleia       "Format on save (like conform.nvim)" "init-formatting")
    (flymake-ruff   "Ruff linter for Python"       "init-formatting")

    ;; init-git.el
    (magit          "Git UI (like lazygit)"         "init-git")
    (diff-hl        "Git gutter (like gitsigns)"    "init-git")
    (blamer         "Inline git blame"              "init-git")

    ;; init-search.el
    (wgrep          "Editable grep (like spectre)"  "init-search")
    (consult-eglot  "LSP symbols via consult"       "init-search")

    ;; init-terminal.el
    (vterm          "Terminal (like toggleterm)"     "init-terminal")
    (vterm-toggle   "Terminal toggle"               "init-terminal")

    ;; init-languages.el
    (go-mode        "Go language support"           "init-languages")
    (rust-mode      "Rust language support"         "init-languages")
    (web-mode       "Web template mode"             "init-languages")
    (emmet-mode     "Emmet abbreviations"           "init-languages")
    (yaml-mode      "YAML support"                  "init-languages")
    (markdown-mode  "Markdown support"              "init-languages")
    (grip-mode      "Markdown preview (like markdown-preview)" "init-languages")
    (csv-mode       "CSV support"                   "init-languages")
    (dockerfile-mode "Dockerfile support"           "init-languages")

    ;; init-debug.el
    (dape           "Debug adapter (like nvim-dap)" "init-debug")

    ;; init-notebook.el
    (jupyter        "Jupyter integration (like molten)" "init-notebook")
    (code-cells     "Cell navigation"               "init-notebook")

    ;; init-ai.el
    (copilot        "GitHub Copilot"                "init-ai")
    (gptel          "LLM chat (like CopilotChat)"   "init-ai")

    ;; init-utils.el
    (which-key      "Keybinding hints"              "init-utils")
    (hl-todo        "TODO highlighting"             "init-utils")
    (writeroom-mode "Zen mode"                      "init-utils")
    (highlight-indent-guides "Indent guides (like indent-blankline)" "init-utils"))
  "期待されるパッケージのリスト: (SYMBOL DESCRIPTION MODULE)")

(defvar my/expected-builtins
  '(;; init-lsp.el
    (eglot          "LSP client (like nvim-lspconfig)" "init-lsp")
    ;; init-formatting.el
    (flymake        "Linter framework (like nvim-lint)" "init-formatting")
    ;; init-treesit.el
    (treesit        "Tree-sitter (built-in)"       "init-treesit")
    ;; init-project.el
    (project        "Project management"            "init-project")
    (desktop        "Session save (like auto-session)" "init-project")
    (midnight       "Buffer cleanup"                "init-project")
    (hideshow       "Code folding (like nvim-ufo)"  "init-project")
    ;; init-core.el
    (recentf        "Recent files"                  "init-core")
    (savehist       "Minibuffer history"             "init-core")
    (saveplace      "Remember cursor position"       "init-core")
    (autorevert     "Auto-revert files"              "init-core")
    ;; init-utils.el
    (which-func     "Breadcrumb (like dropbar)"     "init-utils"))
  "ビルトインパッケージのリスト: (SYMBOL DESCRIPTION MODULE)")

(defvar my/expected-lsp-servers
  '(("pyright-langserver" "Python"     "npm i -g pyright")
    ("gopls"              "Go"         "go install golang.org/x/tools/gopls@latest")
    ("rust-analyzer"      "Rust"       "rustup component add rust-analyzer")
    ("typescript-language-server" "TypeScript" "npm i -g typescript-language-server typescript")
    ("vscode-json-language-server" "JSON"  "npm i -g vscode-langservers-extracted")
    ("yaml-language-server" "YAML"     "npm i -g yaml-language-server")
    ("vscode-html-language-server" "HTML"  "npm i -g vscode-langservers-extracted")
    ("vscode-css-language-server"  "CSS"   "npm i -g vscode-langservers-extracted")
    ("bash-language-server" "Bash"     "npm i -g bash-language-server")
    ("tailwindcss-language-server" "Tailwind" "npm i -g @tailwindcss/language-server"))
  "LSP サーバーのリスト: (COMMAND LANGUAGE INSTALL-CMD)")

(defun verify-packages ()
  "全パッケージのインストール状態を確認し、結果をバッファに表示する。"
  (interactive)
  (let ((buf (get-buffer-create "*Package Verification*"))
        (ok 0) (fail 0) (total 0)
        (srv-ok 0) (srv-fail 0) (srv-total 0))
    (with-current-buffer buf
      (erase-buffer)
      (insert "╔══════════════════════════════════════════════════════════════╗\n")
      (insert "║           Emacs Package Verification Report                ║\n")
      (insert "╚══════════════════════════════════════════════════════════════╝\n\n")

      ;; --- External packages ---
      (insert "━━━ External Packages (straight.el) ━━━\n\n")
      (insert (format "  %-30s %-8s %s\n" "PACKAGE" "STATUS" "MODULE"))
      (insert (make-string 70 ?─) "\n")
      (dolist (entry my/expected-packages)
        (let* ((pkg (nth 0 entry))
               (desc (nth 1 entry))
               (mod (nth 2 entry))
               (installed (or (featurep pkg)
                              (locate-library (symbol-name pkg))
                              (and (boundp 'straight--recipe-cache)
                                   (gethash (symbol-name pkg) straight--recipe-cache)))))
          (setq total (1+ total))
          (if installed
              (progn (setq ok (1+ ok))
                     (insert (format "  %-30s ✅ OK    %s\n" pkg mod)))
            (setq fail (1+ fail))
            (insert (format "  %-30s ❌ MISS  %s  -- %s\n" pkg mod desc)))))

      ;; --- Built-in packages ---
      (insert (format "\n━━━ Built-in Packages ━━━\n\n"))
      (insert (format "  %-30s %-8s %s\n" "PACKAGE" "STATUS" "MODULE"))
      (insert (make-string 70 ?─) "\n")
      (dolist (entry my/expected-builtins)
        (let* ((pkg (nth 0 entry))
               (mod (nth 2 entry))
               (available (or (featurep pkg)
                              (locate-library (symbol-name pkg)))))
          (setq total (1+ total))
          (if available
              (progn (setq ok (1+ ok))
                     (insert (format "  %-30s ✅ OK    %s\n" pkg mod)))
            (setq fail (1+ fail))
            (insert (format "  %-30s ❌ MISS  %s\n" pkg mod)))))

      ;; --- LSP servers ---
      (insert (format "\n━━━ LSP Servers ━━━\n\n"))
      (insert (format "  %-35s %-10s %-8s %s\n" "SERVER" "LANGUAGE" "STATUS" "INSTALL"))
      (insert (make-string 85 ?─) "\n")
      (dolist (entry my/expected-lsp-servers)
        (let* ((cmd (nth 0 entry))
               (lang (nth 1 entry))
               (install (nth 2 entry))
               (found (executable-find cmd)))
          (setq srv-total (1+ srv-total))
          (if found
              (progn (setq srv-ok (1+ srv-ok))
                     (insert (format "  %-35s %-10s ✅ OK\n" cmd lang)))
            (setq srv-fail (1+ srv-fail))
            (insert (format "  %-35s %-10s ❌ MISS  %s\n" cmd lang install)))))

      ;; --- Summary ---
      (insert (format "\n━━━ Summary ━━━\n\n"))
      (insert (format "  Packages:    %d/%d installed" ok total))
      (when (> fail 0)
        (insert (format "  (%d missing)" fail)))
      (insert "\n")
      (insert (format "  LSP Servers: %d/%d available" srv-ok srv-total))
      (when (> srv-fail 0)
        (insert (format "  (%d missing)" srv-fail)))
      (insert "\n")

      (if (and (= fail 0) (= srv-fail 0))
          (insert "\n  🎉 All packages and servers are ready!\n")
        (insert "\n  ⚠  Some items are missing. See above for details.\n")
        (when (> fail 0)
          (insert "     Missing packages will be installed on next Emacs restart.\n"))
        (when (> srv-fail 0)
          (insert "     Run the listed install commands for missing LSP servers.\n")))

      (goto-char (point-min)))
    (switch-to-buffer buf)))

(provide 'verify-packages)
