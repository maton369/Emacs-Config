# Vanilla Emacs 設定

Neovim から移植した **Emacs 29+** 設定。

## 主な機能

- **Evil mode** — Vim キーバインド
- **Eglot** — 10 以上の言語の LSP サポート
- **Corfu + Vertico** — 高速補完とミニバッファ UI
- **Magit** — Git ポーセリン
- **Org + LaTeX** — org-fragtog, citar, lualatex PDF エクスポート
- **pdf-tools** — エディタ内 PDF ビューア
- **Catppuccin Mocha** — Neovim と統一のテーマ

## クイックスタート

```bash
./setup.sh
emacs -nw
```

## SSH リモート接続 (TRAMP)

### コマンドラインから

```bash
# リモートディレクトリを開く
emacs -nw /ssh:hostname:~/project/

# 特定のファイルを開く
emacs -nw /ssh:hostname:~/project/main.py

# Vanilla Emacs を指定して起動（Doom Emacs がデフォルトの場合）
emacs --init-directory ~/.emacs.d -nw /ssh:hostname:~/project/
```

### Emacs 内から

```
C-x C-f /ssh:hostname:~/project/ RET
```

リモートディレクトリが dired で開く。ファイルを直接開く場合:

```
C-x C-f /ssh:hostname:~/project/main.py RET
```

> `~/.ssh/config` のホスト名が使用可能。

## キーバインド

### 一般

| キー | 操作 |
|------|------|
| `SPC ff` | ファイル検索 |
| `SPC fg` | ライブ grep (ripgrep) |
| `SPC gg` | Magit ステータス |
| `SPC ca` | コードアクション |
| `SPC tt` | ターミナル切り替え |
| `gd` | 定義へジャンプ |
| `gr` | 参照検索 |
| `K` | ホバードキュメント |
| `gcc` | コメント切り替え |
| `s` | Avy ジャンプ |

### Org + LaTeX

| キー | 操作 |
|------|------|
| `C-c C-x C-l` | LaTeX プレビュー切り替え |
| `C-c C-,` | 文献挿入 (citar) |
| `C-c C-e` | エクスポート |
| `C-x C-s` | 保存（.tex は自動コンパイル → PDF） |

## パッケージ対応表

```
Neovim プラグイン     ->  Emacs 対応パッケージ
---------------------------------------------
lazy.nvim            ->  straight.el
telescope.nvim       ->  vertico + consult
nvim-cmp             ->  corfu + cape
nvim-lspconfig       ->  eglot (組み込み)
neo-tree             ->  treemacs
lazygit              ->  magit
gitsigns             ->  diff-hl
conform.nvim         ->  apheleia
nvim-dap             ->  dape
toggleterm           ->  vterm
flash.nvim           ->  avy
```

## ディレクトリ構成

```
~/.emacs.d/
├── early-init.el       # GC 最適化、UI 抑制
├── init.el             # straight.el 初期化、モジュール読み込み
└── lisp/
    ├── init-core.el        # 基本エディタ設定
    ├── init-evil.el        # Evil + evil-collection + general.el
    ├── init-ui.el          # テーマ、モードライン、treemacs、タブ
    ├── init-completion.el  # Corfu, Vertico, スニペット
    ├── init-editing.el     # Surround, コメント, avy, マルチカーソル
    ├── init-treesit.el     # Tree-sitter, rainbow-delimiters
    ├── init-lsp.el         # Eglot + eldoc-box
    ├── init-formatting.el  # Apheleia, Flymake
    ├── init-git.el         # Magit, diff-hl, blamer
    ├── init-search.el      # wgrep, consult-eglot
    ├── init-project.el     # project.el, セッション, 折りたたみ
    ├── init-terminal.el    # vterm
    ├── init-languages.el   # Go, Rust, Web, YAML, Markdown, Org
    ├── init-debug.el       # Dape (DAP)
    ├── init-notebook.el    # Jupyter, code-cells
    ├── init-org.el         # Org + LaTeX, citar, pdf-tools
    ├── init-ai.el          # gptel
    ├── init-keybindings.el # SPC リーダーキーバインド
    └── init-utils.el       # which-key, hl-todo, 起動レイアウト
```

> **注意**: LSP サーバーは外部でインストール（npm/go/rustup）。Mason は使用しない。
