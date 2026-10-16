#!/usr/bin/env bash
# Set up this Neovim config on a machine (macOS or Linux, arm64 or x86_64).
#   ./install.sh             tools + config + plugins
#   ./install.sh --no-tools  just link the config and install plugins
# Safe to run again. Anything it replaces is moved to a dated backup, never deleted.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
have() { command -v "$1" >/dev/null 2>&1; }
say() { printf '\n== %s\n' "$*"; }

OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64) TS_ASSET=macos-arm64; LUALS_ASSET=darwin-arm64 ;;
  Darwin-x86_64) TS_ASSET=macos-x64; LUALS_ASSET=darwin-x64 ;;
  Linux-x86_64) TS_ASSET=linux-x64; LUALS_ASSET=linux-x64 ;;
  Linux-aarch64) TS_ASSET=linux-arm64; LUALS_ASSET=linux-arm64 ;;
  *) echo "Unsupported system: $OS-$ARCH" >&2; exit 1 ;;
esac

install_tools() {
  say "Neovim, ripgrep, fd"
  if [ "$OS" = Darwin ]; then
    brew install neovim ripgrep fd
    [ -d /Applications/Ghostty.app ] || brew install --cask ghostty
  else
    echo "Install neovim (0.12 or newer), ripgrep and fd with your package manager, and Ghostty from ghostty.org."
  fi

  say "Rust: rust-analyzer"
  if have rustup; then rustup component add rust-analyzer; else echo "No rustup: install Rust from rustup.rs first."; fi

  say "Python: basedpyright (types) and ruff (lint + format)"
  if have npm; then npm install -g basedpyright; else echo "No npm: install Node (e.g. nvm), then: npm install -g basedpyright"; fi
  # ruff from its official wheel, in its own venv (Homebrew builds it from source on older macOS).
  python3 -m venv "$HOME/.local/share/ruff-venv"
  "$HOME/.local/share/ruff-venv/bin/pip" install -q --upgrade ruff
  ln -sf "$HOME/.local/share/ruff-venv/bin/ruff" "$BIN/ruff"

  say "tree-sitter CLI and lua-language-server (official release binaries, via gh)"
  have gh || { echo "Needs the gh CLI (brew install gh; gh auth login)." >&2; exit 1; }
  TMP="$(mktemp -d)"
  gh release download -R tree-sitter/tree-sitter -p "tree-sitter-cli-$TS_ASSET.zip" -D "$TMP"
  unzip -o -q "$TMP/tree-sitter-cli-$TS_ASSET.zip" -d "$TMP/ts"
  install -m 755 "$TMP/ts/tree-sitter" "$BIN/tree-sitter"
  LUALS_TAG="$(gh release view -R LuaLS/lua-language-server --json tagName --jq .tagName)"
  gh release download "$LUALS_TAG" -R LuaLS/lua-language-server -p "lua-language-server-$LUALS_TAG-$LUALS_ASSET.tar.gz" -D "$TMP"
  rm -rf "$HOME/.local/share/lua-language-server"; mkdir -p "$HOME/.local/share/lua-language-server"
  tar -xzf "$TMP/lua-language-server-$LUALS_TAG-$LUALS_ASSET.tar.gz" -C "$HOME/.local/share/lua-language-server"
  printf '#!/bin/sh\nexec "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$@"\n' > "$BIN/lua-language-server"
  chmod +x "$BIN/lua-language-server"
  [ "$OS" = Darwin ] && xattr -dr com.apple.quarantine "$BIN/tree-sitter" "$HOME/.local/share/lua-language-server" 2>/dev/null || true
  rm -rf "$TMP"
  case ":$PATH:" in *":$BIN:"*) ;; *) echo "Add $BIN to your PATH." ;; esac
}

# Move $1 aside to $1.bak-<date> unless it's already the link we want.
backup() {
  local path="$1" want="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$want" ]; then return; fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    mv "$path" "$path.bak-$STAMP"
    echo "Moved old $path to $path.bak-$STAMP"
  fi
}

link_config() {
  say "Linking the config"
  mkdir -p "$HOME/.config"
  backup "$HOME/.config/nvim" "$HERE"
  ln -sfn "$HERE" "$HOME/.config/nvim"
  echo "~/.config/nvim -> $HERE"

  # Plugins from an old setup in pack/*/start load automatically, so move them aside.
  local old_pack="$HOME/.local/share/nvim/site/pack/plugins"
  if [ -d "$old_pack" ]; then
    mv "$old_pack" "$HOME/.local/share/nvim/old-pack-plugins.bak-$STAMP"
    echo "Moved old plugins to ~/.local/share/nvim/old-pack-plugins.bak-$STAMP"
  fi

  mkdir -p "$HOME/.config/ghostty"
  backup "$HOME/.config/ghostty/config" "$HERE/ghostty/config"
  ln -sfn "$HERE/ghostty/config" "$HOME/.config/ghostty/config"
  echo "~/.config/ghostty/config -> $HERE/ghostty/config"
}

install_plugins() {
  say "Installing plugins and syntax parsers (a minute or two the first time)"
  TERM_PROGRAM=ghostty nvim --headless \
    "+lua require('nvim-treesitter').install(require('cat.languages')):wait(600000)" "+qa!"
  echo
  echo "Done. Open Ghostty and run nvim. :checkhealth shows anything missing."
}

[ "${1:-}" = "--no-tools" ] || install_tools
link_config
install_plugins
