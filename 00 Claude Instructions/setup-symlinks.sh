#!/usr/bin/env bash
# 新しいPCで Obsidian Vault を clone した後に実行する。
# Claude / Codex に Vault 内ファイルへの symlink を張る。
#
# 使い方:
#   bash ~/Documents/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh

set -euo pipefail

VAULT="$HOME/Documents/Obsidian Vault/00 Claude Instructions"
DESKTOP_PROJECT_DIR="$HOME/.claude/projects/-Users-$(whoami)-Desktop"

if [ ! -d "$VAULT" ]; then
  echo "Error: Vault not found at: $VAULT" >&2
  echo "先に Obsidian Vault を ~/Documents/Obsidian\\ Vault に clone してください。" >&2
  exit 1
fi

mkdir -p "$HOME/.claude" "$HOME/.codex" "$DESKTOP_PROJECT_DIR"

# 1) Claude グローバル指示
if [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
  mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak.$(date +%Y%m%d)"
  echo "既存の ~/.claude/CLAUDE.md をバックアップしました"
fi
ln -sfn "$VAULT/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# 2) Claude memory (auto memory)
if [ -e "$DESKTOP_PROJECT_DIR/memory" ] && [ ! -L "$DESKTOP_PROJECT_DIR/memory" ]; then
  mv "$DESKTOP_PROJECT_DIR/memory" "$DESKTOP_PROJECT_DIR/memory.bak.$(date +%Y%m%d)"
  echo "既存の memory ディレクトリをバックアップしました"
fi
ln -sfn "$VAULT/memory" "$DESKTOP_PROJECT_DIR/memory"

# 3) Codex AGENTS.md
if [ -e "$HOME/.codex/AGENTS.md" ] && [ ! -L "$HOME/.codex/AGENTS.md" ]; then
  mv "$HOME/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md.bak.$(date +%Y%m%d)"
  echo "既存の ~/.codex/AGENTS.md をバックアップしました"
fi
ln -sfn "$VAULT/AGENTS.md" "$HOME/.codex/AGENTS.md"

echo ""
echo "=== 完了 ==="
echo "Symlinks created:"
ls -la "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$DESKTOP_PROJECT_DIR/memory"
