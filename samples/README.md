# Vanilla Emacs Config

Neovim から移植した **Emacs 29+** 向け設定ファイル群。

## Features

- **Evil mode** — Vim キーバインド完全互換
- **Eglot** — 10 言語の LSP サーバー対応
- **Corfu + Vertico** — 高速な補完 & ミニバッファ UI
- **Magit** — Git 操作の決定版
- **Catppuccin Mocha** — Neovim と同じテーマ

## Quick Start
  * [x] 
```bash
./setup.sh
emacs -nw
```

## Keybindings

| Key | Action |
|-----|--------|
| `SPC ff` | Find files |
| `SPC fg` | Live grep (ripgrep) |
| `SPC gg` | Magit status |
| `SPC ca` | Code action |
| `SPC tt` | Toggle terminal |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `gcc` | Toggle comment |
| `s` | Avy jump |

## Package Mapping

```
Neovim Plugin        →  Emacs Equivalent
─────────────────────────────────────────
lazy.nvim            →  straight.el
telescope.nvim       →  vertico + consult
nvim-cmp             →  corfu + cape
nvim-lspconfig       →  eglot (built-in)
neo-tree             →  treemacs
lazygit              →  magit
gitsigns             →  diff-hl
conform.nvim         →  apheleia
nvim-dap             →  dape
toggleterm           →  vterm
flash.nvim           →  avy
```

## Directory Structure

```
~/.emacs.d/
├── early-init.el       # GC optimization, UI suppression
├── init.el             # Bootstrap straight.el, load modules
└── lisp/
    ├── init-core.el        # Basic editor settings
    ├── init-evil.el        # Evil + evil-collection + general.el
    ├── init-ui.el          # Theme, modeline, treemacs, tabs
    ├── init-completion.el  # Corfu, Vertico, snippets
    ├── init-editing.el     # Surround, comment, avy, multi-cursor
    ├── init-treesit.el     # Tree-sitter, rainbow delimiters
    ├── init-lsp.el         # Eglot + eldoc-box
    ├── init-formatting.el  # Apheleia, Flymake
    ├── init-git.el         # Magit, diff-hl, blamer
    ├── init-search.el      # wgrep, consult-eglot
    ├── init-project.el     # project.el, sessions, folding
    ├── init-terminal.el    # vterm
    ├── init-languages.el   # Go, Rust, Web, YAML, Markdown, Org
    ├── init-debug.el       # Dape (DAP)
    ├── init-notebook.el    # Jupyter, code-cells
    ├── init-ai.el          # gptel
    ├── init-keybindings.el # All SPC leader bindings
    └── init-utils.el       # which-key, hl-todo, startup layout
```

> **Note**: LSP servers are installed externally (npm/go/rustup), not via Mason.
