#!/usr/bin/env bash
# 新しいPCで Obsidian Vault を Google Drive 同期した後に実行する。
# Claude / Codex に Vault 内ファイルへの symlink を張る。
#
# 前提:
#   1) Google Drive アプリがインストール・ログイン済み
#   2) Drive 同期で `~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian Vault/` が見えている
#   3) Obsidian で当該 Vault を一度開いて「作成者を信頼」済み
#
# 使い方:
#   bash "$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh)"
#
# オプション:
#   --workdir <path>   Claude Code を実行する作業ディレクトリ (デフォルト: マイドライブ直下)
#                      ここの memory が Vault と共有される

set -euo pipefail

# ---- パス解決 ----
WORKDIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

VAULT_DIR=$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian\ Vault/00\ Claude\ Instructions 2>/dev/null | head -n1)
if [ ! -d "$VAULT_DIR" ]; then
  echo "Error: Vault が見つからない: ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian Vault/00 Claude Instructions" >&2
  echo "Google Drive 同期が完了しているか確認してください。" >&2
  exit 1
fi
echo "Vault: $VAULT_DIR"

if [ -z "$WORKDIR" ]; then
  WORKDIR=$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ | head -n1)
fi
if [ ! -d "$WORKDIR" ]; then
  echo "Error: workdir が見つからない: $WORKDIR" >&2
  exit 1
fi
echo "Workdir: $WORKDIR"

# ---- プロジェクトハッシュ計算 (Claude Code 規約: 非英数字を '-' に置換) ----
PROJECT_HASH=$(python3 -c "import sys, re; print(re.sub(r'[^a-zA-Z0-9-]', '-', sys.argv[1]))" "$WORKDIR")
PROJECT_DIR="$HOME/.claude/projects/$PROJECT_HASH"
echo "Project dir: $PROJECT_DIR"

mkdir -p "$HOME/.claude" "$PROJECT_DIR"

# ---- 1) Claude グローバル指示 ----
target_claude_md="$VAULT_DIR/CLAUDE.md"
link_claude_md="$HOME/.claude/CLAUDE.md"
if [ -e "$link_claude_md" ] && [ ! -L "$link_claude_md" ]; then
  mv "$link_claude_md" "$link_claude_md.bak.$(date +%Y%m%d-%H%M%S)"
  echo "既存の ~/.claude/CLAUDE.md をバックアップしました"
fi
ln -sfn "$target_claude_md" "$link_claude_md"
echo "✓ ~/.claude/CLAUDE.md -> $target_claude_md"

# ---- 2) Claude memory (auto memory) ----
target_memory="$VAULT_DIR/memory"
link_memory="$PROJECT_DIR/memory"
if [ -e "$link_memory" ] && [ ! -L "$link_memory" ]; then
  mv "$link_memory" "$link_memory.bak.$(date +%Y%m%d-%H%M%S)"
  echo "既存の memory ディレクトリをバックアップしました"
fi
ln -sfn "$target_memory" "$link_memory"
echo "✓ $link_memory -> $target_memory"

# ---- 3) Codex AGENTS.md (~/.codex 存在時のみ) ----
if [ -d "$HOME/.codex" ]; then
  target_agents="$VAULT_DIR/AGENTS.md"
  link_agents="$HOME/.codex/AGENTS.md"
  if [ -e "$link_agents" ] && [ ! -L "$link_agents" ]; then
    mv "$link_agents" "$link_agents.bak.$(date +%Y%m%d-%H%M%S)"
    echo "既存の ~/.codex/AGENTS.md をバックアップしました"
  fi
  ln -sfn "$target_agents" "$link_agents"
  echo "✓ ~/.codex/AGENTS.md -> $target_agents"
else
  echo "(Codex 未インストール: ~/.codex/AGENTS.md はスキップ)"
fi

# ---- 4) Claude scripts (Stop hookで実行する) ----
# セキュリティ上 symlink ではなく実コピー。Vault側を編集後にこのスクリプトを再実行で反映。
mkdir -p "$HOME/.claude/scripts"
for src in "$VAULT_DIR/scripts/"*.py; do
  [ -e "$src" ] || continue
  dst="$HOME/.claude/scripts/$(basename "$src")"
  cp "$src" "$dst"
  chmod +x "$dst"
  echo "✓ $dst (copy from Vault)"
done

# ---- 5) settings.json テンプレート (初回のみ) ----
target_settings="$VAULT_DIR/settings.template.json"
link_settings="$HOME/.claude/settings.json"
if [ -e "$target_settings" ]; then
  if [ ! -e "$link_settings" ]; then
    cp "$target_settings" "$link_settings"
    echo "✓ ~/.claude/settings.json を初回作成 (テンプレートから)"
  else
    echo "(~/.claude/settings.json は既存。テンプレートとの差分は手動マージ: diff $link_settings $target_settings )"
  fi
fi

echo ""
echo "=== 完了 ==="
ls -la "$link_claude_md" "$link_memory" 2>&1
[ -d "$HOME/.codex" ] && ls -la "$HOME/.codex/AGENTS.md" 2>&1
echo ""
echo "Claude Code を再起動すると CLAUDE.md と memory が読み込まれます。"
echo "Stop hook (会話ログのObsidian保管) も有効化されます。"
