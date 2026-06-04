#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Vanilla Emacs 開発環境セットアップスクリプト
#
# 対応 OS: macOS (Homebrew) / Ubuntu・Debian (apt)
#
# 使い方:
#   chmod +x setup.sh
#   ./setup.sh            # 通常インストール
#   ./setup.sh --clean    # 既存設定を削除して再インストール
# ==============================================================================

echo "=== Vanilla Emacs 開発環境セットアップ ==="
echo ""

EMACS_DIR="${HOME}/.emacs.d"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------- OS 判定 ----------
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  PLATFORM="mac"
  echo "検出: macOS"
elif [ -f /etc/os-release ] && grep -qi 'ubuntu\|debian' /etc/os-release; then
  PLATFORM="ubuntu"
  echo "検出: Ubuntu / Debian"
else
  echo "Error: macOS または Ubuntu/Debian のみ対応しています"
  exit 1
fi
echo ""

# ---------- パッケージマネージャの準備 ----------
install_pkg() {
  local pkg="$1"
  if [ "$PLATFORM" = "mac" ]; then
    if brew list "$pkg" &>/dev/null; then
      echo "  ✓ $pkg (インストール済み)"
    else
      echo "  → $pkg をインストール中..."
      brew install "$pkg"
    fi
  else
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
      echo "  ✓ $pkg (インストール済み)"
    else
      echo "  → $pkg をインストール中..."
      sudo apt-get install -y -qq "$pkg"
    fi
  fi
}

install_cask() {
  local cask="$1"
  if brew list --cask "$cask" &>/dev/null; then
    echo "  ✓ $cask (インストール済み)"
  else
    echo "  → $cask をインストール中..."
    brew install --cask "$cask"
  fi
}

# ---------- [1/9] システムツール ----------
echo "[1/9] システムツールをインストール..."

if [ "$PLATFORM" = "mac" ]; then
  if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew が見つかりません。先にインストールしてください:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
  mac_packages=(git node python3 go rustup ripgrep fd cmake libtool pandoc poppler imagemagick)
  for pkg in "${mac_packages[@]}"; do
    install_pkg "$pkg"
  done

  # Emacs (GUI版 cask)
  if brew list --cask emacs-app &>/dev/null; then
    echo "  ✓ emacs-app (インストール済み)"
  else
    echo "  → Emacs (GUI版) をインストール中..."
    # 壊れた Emacs.app があれば削除
    [ -f /Applications/Emacs.app ] && rm -f /Applications/Emacs.app
    brew install --cask emacs-app
  fi
  EMACS_BIN="/Applications/Emacs.app/Contents/MacOS/Emacs"
else
  sudo apt-get update -qq

  # Emacs 29+
  if ! command -v emacs &>/dev/null; then
    echo "  → Emacs をインストール中..."
    sudo apt-get install -y -qq software-properties-common
    sudo add-apt-repository -y ppa:kelleyk/emacs
    sudo apt-get update -qq
    sudo apt-get install -y -qq emacs29
  else
    echo "  ✓ emacs (インストール済み)"
  fi
  EMACS_BIN="emacs"

  apt_packages=(
    git
    curl
    build-essential   # make, gcc
    python3
    python3-venv
    python3-pip
    golang
    ripgrep
    fd-find
    cmake             # vterm ビルドに必要
    libtool-bin       # vterm ビルドに必要
    pandoc            # Markdown プレビュー
    poppler-utils     # pdftotext
    unzip
    imagemagick
  )
  for pkg in "${apt_packages[@]}"; do
    install_pkg "$pkg"
  done

  # fd-find は Ubuntu ではバイナリ名が fdfind
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
  fi

  # Node.js (なければ NodeSource から)
  if ! command -v node &>/dev/null; then
    echo "  → Node.js をインストール中..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
  else
    echo "  ✓ nodejs (インストール済み)"
  fi

  # Rust (rustup)
  if ! command -v rustup &>/dev/null; then
    echo "  → Rust をインストール中..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
  else
    echo "  ✓ rustup (インストール済み)"
  fi
fi

# Rust ツールチェインの初期化
if command -v rustup &>/dev/null && ! rustup show active-toolchain &>/dev/null 2>&1; then
  echo "  → Rust ツールチェインを初期化中..."
  rustup default stable
fi

# ---------- [2/9] LaTeX 環境 ----------
echo ""
echo "[2/9] LaTeX 環境をインストール..."

if [ "$PLATFORM" = "mac" ]; then
  # macOS: MacTeX (フル版)
  if command -v lualatex &>/dev/null; then
    echo "  ✓ lualatex (インストール済み)"
  else
    echo "  → MacTeX をインストール中... (約 5GB、時間がかかります)"
    install_cask mactex
    # MacTeX は /Library/TeX/texbin にインストールされる
    eval "$(/usr/libexec/path_helper -s)" 2>/dev/null || true
    export PATH="/Library/TeX/texbin:$PATH"
  fi
else
  # Ubuntu: texlive-full
  if command -v lualatex &>/dev/null; then
    echo "  ✓ lualatex (インストール済み)"
  else
    echo "  → TeX Live をインストール中..."
    sudo apt-get install -y -qq texlive-full
  fi
fi

# tlmgr で追加パッケージをインストール
# dvipng / dvisvgm: フォールバック用（メインは pdftoppm）
# latexmk: LaTeX ビルド自動化
tlmgr_packages=(dvipng dvisvgm latexmk)
for pkg in "${tlmgr_packages[@]}"; do
  if command -v "$pkg" &>/dev/null; then
    echo "  ✓ $pkg (インストール済み)"
  else
    echo "  → $pkg をインストール中..."
    sudo tlmgr install "$pkg" 2>/dev/null || echo "  ⚠ $pkg のインストールに失敗。sudo tlmgr install $pkg を手動で実行してください"
  fi
done

# texlab (LaTeX LSP サーバー)
if command -v texlab &>/dev/null; then
  echo "  ✓ texlab (インストール済み)"
else
  echo "  → texlab をインストール中..."
  if [ "$PLATFORM" = "mac" ]; then
    brew install texlab
  else
    # Ubuntu: cargo でインストール
    if command -v cargo &>/dev/null; then
      cargo install texlab
    else
      echo "  ⚠ cargo が見つかりません。texlab をスキップします。"
    fi
  fi
fi

# LaTeX コマンドの確認
echo ""
echo "  LaTeX コマンド確認:"
for cmd in latex pdflatex lualatex latexmk bibtex biber dvipdfmx dvipng dvisvgm pdftoppm; do
  if command -v "$cmd" &>/dev/null; then
    echo "    ✓ $cmd"
  else
    echo "    ✗ $cmd"
  fi
done

# ---------- [3/9] Node.js ツール (npm) ----------
echo ""
echo "[3/9] Node.js ツールをインストール..."
npm_packages=(prettier prettierd eslint_d)

for pkg in "${npm_packages[@]}"; do
  if npm list -g "$pkg" &>/dev/null 2>&1; then
    echo "  ✓ $pkg (インストール済み)"
  else
    echo "  → $pkg をインストール中..."
    npm install -g "$pkg"
  fi
done

# ---------- [4/9] Python ツール ----------
echo ""
echo "[4/9] Python ツールをインストール..."

if command -v ruff &>/dev/null; then
  echo "  ✓ ruff (インストール済み)"
else
  echo "  → ruff をインストール中..."
  pip install --break-system-packages ruff 2>/dev/null || pip install ruff
fi

# ---------- [5/9] LSP サーバー ----------
echo ""
echo "[5/9] LSP サーバーをインストール..."

# npm ベース LSP
lsp_npm_packages=(
  "pyright"
  "typescript-language-server"
  "typescript"
  "vscode-langservers-extracted"
  "yaml-language-server"
  "bash-language-server"
  "@tailwindcss/language-server"
)

for pkg in "${lsp_npm_packages[@]}"; do
  if npm list -g "$pkg" &>/dev/null 2>&1; then
    echo "  ✓ $pkg (インストール済み)"
  else
    echo "  → $pkg をインストール中..."
    npm install -g "$pkg"
  fi
done

# Go LSP
if command -v go &>/dev/null; then
  if command -v gopls &>/dev/null; then
    echo "  ✓ gopls (インストール済み)"
  else
    echo "  → gopls をインストール中..."
    go install golang.org/x/tools/gopls@latest
  fi
else
  echo "  ⚠ Go が見つかりません。gopls をスキップします。"
fi

# Rust LSP
if command -v rustup &>/dev/null; then
  if rustup component list --installed 2>/dev/null | grep -q rust-analyzer; then
    echo "  ✓ rust-analyzer (インストール済み)"
  else
    echo "  → rust-analyzer をインストール中..."
    rustup component add rust-analyzer
  fi
else
  echo "  ⚠ rustup が見つかりません。rust-analyzer をスキップします。"
fi

# Go デバッガ
if command -v go &>/dev/null; then
  if command -v dlv &>/dev/null; then
    echo "  ✓ delve (インストール済み)"
  else
    echo "  → delve をインストール中..."
    go install github.com/go-delve/delve/cmd/dlv@latest
  fi
fi

# ---------- [6/9] Emacs 設定ファイルのインストール ----------
echo ""
echo "[6/9] Emacs 設定ディレクトリをリンク..."

if [ "$(readlink "$EMACS_DIR" 2>/dev/null)" = "$SCRIPT_DIR" ]; then
  echo "  ✓ $EMACS_DIR → $SCRIPT_DIR (リンク済み)"
elif [ -e "$EMACS_DIR" ]; then
  if [ "${1:-}" = "--clean" ]; then
    echo "  → 既存の $EMACS_DIR を削除中... (--clean)"
    rm -rf "$EMACS_DIR"
  else
    backup="${EMACS_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  → 既存の $EMACS_DIR をバックアップ: $backup"
    mv "$EMACS_DIR" "$backup"
  fi
  ln -s "$SCRIPT_DIR" "$EMACS_DIR"
  echo "  ✓ $EMACS_DIR → $SCRIPT_DIR"
else
  ln -s "$SCRIPT_DIR" "$EMACS_DIR"
  echo "  ✓ $EMACS_DIR → $SCRIPT_DIR"
fi

# stale .elc 削除
elc_count=$(find "$EMACS_DIR/lisp" -name "*.elc" 2>/dev/null | wc -l | tr -d ' ')
if [ "$elc_count" -gt 0 ]; then
  echo "  → 古い .elc ファイルを $elc_count 件削除中..."
  find "$EMACS_DIR/lisp" -name "*.elc" -delete
fi

# ---------- [7/9] Org ディレクトリの準備 ----------
echo ""
echo "[7/9] Org ディレクトリを準備..."

ORG_DIR="$HOME/org"
mkdir -p "$ORG_DIR"
echo "  ✓ $ORG_DIR"

if [ ! -f "$ORG_DIR/references.bib" ]; then
  cat > "$ORG_DIR/references.bib" << 'BIBEOF'
% Bibliography database
% Add entries with BibTeX format, e.g.:
%
% @article{key,
%   author  = {Author Name},
%   title   = {Article Title},
%   journal = {Journal Name},
%   year    = {2024},
% }
BIBEOF
  echo "  ✓ references.bib を作成しました"
else
  echo "  ✓ references.bib (既存)"
fi

# ---------- [8/9] straight.el でパッケージインストール ----------
echo ""
echo "[8/9] straight.el でパッケージをインストール..."
echo "  リポジトリのクローンに数分かかる場合があります。"

"$EMACS_BIN" --batch -l "$EMACS_DIR/init.el" 2>&1 \
  | grep -E "^(Cloning|Building|Failed|Error)" \
  | while IFS= read -r line; do
      case "$line" in
        Failed*|Error*) echo "  ⚠ $line" ;;
        *)              echo "  $line" ;;
      esac
    done

build_count=$(ls "$EMACS_DIR/straight/build/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$build_count" -gt 50 ]; then
  echo "  ✓ $build_count パッケージをインストールしました"
else
  echo "  ⚠ $build_count パッケージのみ。問題がある可能性があります。"
  echo "    手動確認: emacs --batch -l ~/.emacs.d/init.el"
fi

# vterm モジュールの事前コンパイル（初回起動時のフリーズを防止）
echo "  → vterm モジュールをコンパイル中..."
"$EMACS_BIN" --batch -l "$EMACS_DIR/init.el" \
  --eval "(setq vterm-always-compile-module t)" \
  --eval "(require 'vterm)" 2>&1 \
  | grep -v "^$" | head -5 || true
echo "  ✓ vterm モジュールコンパイル完了"

# ---------- [9/9] インストール確認 ----------
echo ""
echo "[9/9] インストール確認..."

# Emacs モジュール
errors=$("$EMACS_BIN" --batch -l "$EMACS_DIR/init.el" 2>&1 | grep -cE "^(Failed|Error)" || true)
if [ "$errors" -eq 0 ]; then
  echo "  ✓ 全モジュール正常にロード"
else
  echo "  ⚠ $errors モジュールにエラーあり"
fi

# LSP サーバー
echo ""
echo "  LSP サーバー確認:"
servers=(
  "pyright-langserver:Python"
  "gopls:Go"
  "rust-analyzer:Rust"
  "typescript-language-server:TypeScript"
  "vscode-json-language-server:JSON"
  "yaml-language-server:YAML"
  "bash-language-server:Bash"
  "texlab:LaTeX"
)
for entry in "${servers[@]}"; do
  cmd="${entry%%:*}"
  lang="${entry#*:}"
  if command -v "$cmd" &>/dev/null; then
    echo "    ✓ $lang ($cmd)"
  else
    echo "    ✗ $lang ($cmd)"
  fi
done

# LaTeX
echo ""
echo "  LaTeX 環境確認:"
for cmd in lualatex latexmk bibtex dvipng dvisvgm pdftoppm; do
  if command -v "$cmd" &>/dev/null; then
    echo "    ✓ $cmd"
  else
    echo "    ✗ $cmd"
  fi
done

# ---------- 完了 ----------
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "確認コマンド:"
echo "  emacsclient -c -a ''  → Emacs を起動 (デーモン自動起動)"
echo ""
echo "推奨エイリアス (.zshrc に追加):"
if [ "$PLATFORM" = "mac" ]; then
echo '  EMACS_APP="/Applications/Emacs.app/Contents/MacOS"'
echo '  export PATH="$EMACS_APP/bin:$PATH"'
fi
echo "  alias emacs=\"emacsclient -c -a ''\""
echo "  alias kill-emacs=\"emacsclient -e '(kill-emacs)'\""
echo ""
echo "初回起動後 (任意):"
echo "  M-x nerd-icons-install-fonts    → Nerd フォントをインストール"
echo ""
echo "注意:"
echo "  - ~/.local/bin が PATH に含まれていることを確認してください"
echo "  - LaTeX の初回利用時はフォントキャッシュの生成に時間がかかる場合があります"
echo ""
