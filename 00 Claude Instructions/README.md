# 00 Claude Instructions

このフォルダは **Claude Code と Codex (OpenAI) の全マシン共通指示** の唯一の真実 (single source of truth)。Obsidian Vault に置いて **Google Drive 同期** することで、複数PCで同じ指示を使う。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | Claude Code グローバル指示。全セッション・全プロジェクトで読まれる。 |
| `AGENTS.md` | Codex 用指示。中身は `CLAUDE.md` への symlink (同じ内容を共有)。 |
| `memory/` | Claude Code の自動記憶ファイル群。MEMORY.md を起点に関連時に読まれる。 |
| `scripts/log-to-obsidian.py` | Claude Code セッション (jsonl) を `Claude Logs/YYYY-MM-DD.md` に集約する Stop hook 用スクリプト。 |
| `settings.template.json` | `~/.claude/settings.json` のテンプレート (Stop hook 登録済み)。 |
| `setup-symlinks.sh` | 新しい PC で実行する初期化スクリプト。指示・memory は symlink、scripts は実コピーする。 |

## symlink の仕組み

| 参照側 (Claude/Codex が見る場所) | 実体 (Vault 内) |
|---|---|
| `~/.claude/CLAUDE.md` | `CLAUDE.md` |
| `~/.claude/projects/<workdir-hash>/memory/` | `memory/` |
| `~/.codex/AGENTS.md` (Codex 入ってる場合のみ) | `AGENTS.md` |
| `AGENTS.md` (Vault 内) | `CLAUDE.md` (Vault 内) |

`<workdir-hash>` は Claude Code を実行する作業ディレクトリの絶対パスを、英数字以外を `-` に置換した文字列。デフォルトは Google Drive のマイドライブ直下を想定。

## 別 PC でのセットアップ

```bash
# 1) Google Drive アプリで Vault を同期
#    ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian Vault/ が見える状態にする

# 2) Obsidian を起動し当該 Vault を開いて「作成者を信頼しプラグインを有効化」をクリック

# 3) symlink を張る
bash "$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh)"

# 4) Claude Code を再起動
```

別ディレクトリで Claude Code を使う場合は `--workdir /path/to/dir` を渡す。

## 編集ワークフロー

- Obsidian でこのフォルダ内のファイルを編集
- Google Drive アプリが自動で同期 (数秒〜数十秒のラグあり)
- 別 PC は同期完了後に最新を受け取る (再起動不要、symlink 越しに常時最新)

## 注意点

- **秘密情報を書かない**: Webhook URL、APIキー、銀行口座、パスワード等。Drive 経由で漏洩面が広がる。
- **コンフリクト時**: Google Drive が `*.conflict` ファイルを作る。Obsidian で差分を見て手動マージ。
- **ロールバック不可**: Git のような履歴は無い。重要な変更前にコピーを取るか、必要なら別途 GitHub に手動 push (`.git/` フォルダは残置)。
- **Codex 固有設定**: プロジェクト固有指示はプロジェクトルートに `AGENTS.md` を別途置く (このグローバル指示とは別)。
