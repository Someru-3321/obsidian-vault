# 00 Claude Instructions

このフォルダは **Claude Code と Codex (OpenAI) の全マシン共通指示** の唯一の真実 (single source of truth)。Obsidian Vault に置いて Git で同期することで、複数PCで同じ指示を使う。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | Claude Code グローバル指示。全セッション・全プロジェクトで読まれる。 |
| `AGENTS.md` | Codex 用指示。中身は `CLAUDE.md` への symlink (同じ内容を共有)。 |
| `memory/` | Claude Code の自動記憶ファイル群。MEMORY.md を起点に関連時に読まれる。 |
| `setup-symlinks.sh` | 新しいPCで実行する初期化スクリプト。`~/.claude/` と `~/.codex/` から Vault 内ファイルへ symlink を張る。 |

## symlink の仕組み

| 参照側 (Claude/Codex が見る場所) | 実体 (Vault 内) |
|---|---|
| `~/.claude/CLAUDE.md` | `CLAUDE.md` |
| `~/.claude/projects/-Users-<user>-Desktop/memory/` | `memory/` |
| `~/.codex/AGENTS.md` | `AGENTS.md` |
| `AGENTS.md` (Vault内) | `CLAUDE.md` (Vault内) |

## 別PCでのセットアップ

```bash
# 1) Vault を clone (HTTPS の例)
git clone https://github.com/<your-username>/obsidian-vault.git ~/Documents/Obsidian\ Vault

# 2) symlink を張る
bash ~/Documents/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh
```

## 編集ワークフロー

- Obsidian でこのフォルダ内のファイルを編集する。
- Obsidian Git プラグインが10分ごとに自動コミット&プッシュ。
- 別PCはプル時に最新を受け取る。

## 注意点

- このリポジトリは **絶対に Private** にすること。memory に個人情報・APIキー・銀行口座等が含まれる可能性。
- Codex (OpenAI) は `~/.codex/AGENTS.md` を認識する。プロジェクト固有指示はプロジェクトルートに `AGENTS.md` を別途置く。
- Claude Code の memory パスはユーザー名と作業ディレクトリで決まる (`-Users-<user>-<workdir>` 形式)。Desktopではなく別ディレクトリで作業するなら symlink パスを別途設定。
