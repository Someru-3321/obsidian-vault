---
name: Claude/Codex 指示 Obsidian Vault 同期システム
description: グローバル CLAUDE.md と memory ファイルを Obsidian Vault に集約し Google Drive で複数PC同期する仕組み
type: project
---
**構成**:
- 真実の源: `~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian Vault/00 Claude Instructions/`
  - `CLAUDE.md` — Claude グローバル指示
  - `AGENTS.md` → `./CLAUDE.md` (symlink、Codex 用に同じ内容)
  - `memory/` — Claude 自動記憶 (このファイル含む)
  - `setup-symlinks.sh` — 新PC初期化スクリプト
  - `README.md` — 仕組み解説
- 参照側 symlink:
  - `~/.claude/CLAUDE.md` → Vault/CLAUDE.md
  - `~/.claude/projects/<workdir-hash>/memory/` → Vault/memory/
  - `~/.codex/AGENTS.md` → Vault/AGENTS.md (Codex入ってる場合のみ)
- 同期: **Google Drive アプリでファイル同期**

**Why**: Claudeの「日本語で返答」等のトーン指示が忘れられる対策＋PC間で同じ指示を使い回す＋Codex も同じ指示で動かす。Obsidian を編集UIにする。

**How to apply**:
- memory ファイルや CLAUDE.md を編集するときは Vault 内のファイルを直接編集 (symlink先)
- Drive 同期は数秒〜数十秒のラグ。別PCはそのまま symlink 越しに最新を読む
- **秘密情報 (Webhook URL, APIキー, 銀行口座等) は絶対に memory/CLAUDE.md に書かない** — Drive 経由で漏洩面が広がる
- 別PCセットアップ: Google Drive アプリで Vault 同期完了 → Obsidian で Vault 開いて Trust → `bash "$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh)"`

**履歴の変遷**:
- 〜2026-05-12: ローカル `~/Documents/Obsidian Vault` + Private GitHub `Someru-3321/obsidian-vault` + Obsidian Git プラグインで PC 間同期
- 2026-05-19: Google Drive 配下に Vault を移動、Obsidian Git プラグイン無効化、Drive 同期に一本化。`.git/` フォルダと GitHub remote はアーカイブとして残置 (`Someru-3321/obsidian-vault`、新規push は手動でのみ可)。同日 [[reference_obsidian_vault]] の通り Obsidian Local REST API & MCP Server プラグインを導入し Claude Code から MCP 経由 Vault アクセス可

**コンフリクト対策**: Drive は競合時 `*.conflict.<timestamp>` ファイルを別途作る。Obsidian の差分プラグイン等で手動マージ。Git のような自動マージは無い。

関連: [[reference_obsidian_vault]]
