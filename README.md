# Emacs 設定

**Emacs 29+** の設定。Evil mode + straight.el。

<img width="1512" height="949" alt="image" src="https://github.com/user-attachments/assets/b2177fb4-f344-45f6-8ef3-7f7f33ed536a" />

## 主な機能

- **Evil mode** — Vim キーバインド
- **Eglot** — 10 以上の言語の LSP サポート
- **Corfu + Vertico** — 高速補完とミニバッファ UI
- **Magit** — Git ポーセリン
- **Org + LaTeX** — org-fragtog, citar, lualatex PDF エクスポート
- **pdf-tools** — エディタ内 PDF ビューア
- **Jupyter** — セル評価と kitty-graphics によるインライン画像表示
- **Catppuccin Mocha** テーマ

## クイックスタート

```bash
./setup.sh
emacs -nw
```

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

### Jupyter (python-ts-mode)

| キー | 操作 |
|------|------|
| `SPC mi` | カーネル起動 |
| `SPC mx` | セル実行 |
| `SPC mX` | セル実行して次へ |
| `SPC mc` | 全セル実行 |
| `SPC md` | 出力クリア |
| `SPC mD` | 診断情報 |
| `]c` / `[c` | 次 / 前のセル |

### Org + LaTeX

| キー | 操作 |
|------|------|
| `C-c C-x C-l` | LaTeX プレビュー切り替え |
| `C-c C-,` | 文献挿入 (citar) |
| `C-c C-e` | エクスポート |
| `C-x C-s` | 保存（.tex は自動コンパイル → PDF） |

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
    ├── init-notebook.el    # Jupyter, code-cells, kitty-graphics
    ├── init-org.el         # Org + LaTeX, citar, pdf-tools
    ├── init-ai.el          # gptel
    ├── init-keybindings.el # SPC リーダーキーバインド
    └── init-utils.el       # which-key, hl-todo, 起動レイアウト
```

> **注意**: LSP サーバーは外部でインストール（npm/go/rustup）。Mason は使用しない。
