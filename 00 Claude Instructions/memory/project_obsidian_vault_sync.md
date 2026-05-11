---
name: Claude/Codex 指示 Obsidian Vault 同期システム
description: グローバル CLAUDE.md と memory ファイルを Obsidian Vault に集約し Private GitHub で複数PC同期する仕組み
type: project
---
**構成**:
- 真実の源: `~/Documents/Obsidian Vault/00 Claude Instructions/`
  - `CLAUDE.md` — Claude グローバル指示
  - `AGENTS.md` → `./CLAUDE.md` (symlink、Codex 用に同じ内容)
  - `memory/` — Claude 自動記憶 (このファイル含む)
  - `setup-symlinks.sh` — 新PC初期化スクリプト
  - `README.md` — 仕組み解説
- 参照側 symlink:
  - `~/.claude/CLAUDE.md` → Vault/CLAUDE.md
  - `~/.claude/projects/-Users-watanabeyuuki-Desktop/memory/` → Vault/memory/
  - `~/.codex/AGENTS.md` → Vault/AGENTS.md
- 同期: Private GitHub `git@github.com:Someru-3321/obsidian-vault.git` (SSH)
- 自動コミット: Obsidian Git プラグイン (Vinzent03) を Obsidian で有効化

**Why**: Claudeの「日本語で返答」等のトーン指示が忘れられる対策＋PC間で同じ指示を使い回す＋Codex も同じ指示で動かす。Obsidian を編集UIにする。

**How to apply**:
- memory ファイルや CLAUDE.md を編集するときは Vault 内のファイルを直接編集（symlink先）
- 秘密情報(Webhook URL, APIキー等)は絶対にmemoryに書かない — GitHub Secret Scanning がpushを拒否する(2026-05-12 にSlack Webhook URLでブロックされた実績あり)
- 別PCセットアップ: `git clone git@github.com:Someru-3321/obsidian-vault.git ~/Documents/Obsidian\ Vault` → `bash ~/Documents/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh`
- 旧 memory バックアップ: `~/.claude/projects/-Users-watanabeyuuki-Desktop/memory.bak.20260512` (dotfilesへのsymlink) と `memory.bak.20260503-220406` (実ディレクトリ) が残置されている

**注意**: 2026-05-12 移行時点で `~/dotfiles/claude-code/` はGit化されていない (`auto_commit_dotfiles.sh` Stopフックは無実行)。dotfilesの同期は別タスク。
