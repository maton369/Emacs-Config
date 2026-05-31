# Vanilla Emacs Config

Neovim from ported **Emacs 29+** configuration.

## Features

- **Evil mode** — Vim keybindings
- **Eglot** — LSP support for 10+ languages
- **Corfu + Vertico** — fast completion & minibuffer UI
- **Magit** — Git porcelain
- **Org + LaTeX** — org-fragtog, citar, lualatex PDF export
- **pdf-tools** — in-editor PDF viewer
- **Catppuccin Mocha** — consistent theme with Neovim

## Quick Start

```bash
./setup.sh
emacs -nw
```

## Remote SSH Connection (TRAMP)

### Method 1: From the command line

```bash
# Open a remote directory
emacs -nw /ssh:hostname:~/project/

# Open a specific file
emacs -nw /ssh:hostname:~/project/main.py

# With vanilla Emacs (if Doom Emacs is the default)
emacs --init-directory ~/.emacs.d -nw /ssh:hostname:~/project/
```

### Method 2: From inside Emacs

```
C-x C-f /ssh:hostname:~/project/ RET
```

This opens the remote directory in dired. You can then navigate and open files.
To open a specific file directly:

```
C-x C-f /ssh:hostname:~/project/main.py RET
```

> Host names from `~/.ssh/config` are available (e.g. `my-server` instead of `user@192.168.1.100`).

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

### Org + LaTeX

| Key | Action |
|-----|--------|
| `C-c C-x C-l` | Toggle LaTeX preview |
| `C-c C-,` | Insert citation (citar) |
| `C-c C-e` | Export dispatcher |
| `C-x C-s` | Save (auto-compiles .tex to PDF) |

## Package Mapping

```
Neovim Plugin        ->  Emacs Equivalent
---------------------------------------------
lazy.nvim            ->  straight.el
telescope.nvim       ->  vertico + consult
nvim-cmp             ->  corfu + cape
nvim-lspconfig       ->  eglot (built-in)
neo-tree             ->  treemacs
lazygit              ->  magit
gitsigns             ->  diff-hl
conform.nvim         ->  apheleia
nvim-dap             ->  dape
toggleterm           ->  vterm
flash.nvim           ->  avy
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
    ├── init-org.el         # Org + LaTeX, citar, pdf-tools
    ├── init-ai.el          # gptel
    ├── init-keybindings.el # All SPC leader bindings
    └── init-utils.el       # which-key, hl-todo, startup layout
```

> **Note**: LSP servers are installed externally (npm/go/rustup), not via Mason.
