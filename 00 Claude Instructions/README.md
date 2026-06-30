# 00 Claude Instructions

このフォルダは **Claude Code と Codex (OpenAI) の全マシン共通指示** の唯一の真実 (single source of truth)。
**Google Drive 自動同期** と **GitHub (`Someru-3321/obsidian-vault`, Private)** の **両方**で同期し、家用PC・外用PC・スマホのどこからでも同じ指示を読み書きできる状態にする。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | Claude Code グローバル指示。全セッション・全プロジェクトで読まれる。 |
| `AGENTS.md` | Codex 用指示の**実ファイル**。共通部分は `CLAUDE.md` と同内容＋Codex 固有の「接続時の注意」。`~/.codex/AGENTS.md` がこれを指す。 |
| `memory/` | Claude Code の自動記憶ファイル群。`MEMORY.md` を起点に関連時に読まれる。 |
| `scripts/log-to-obsidian.py` | Claude Code セッション (jsonl) を `Claude Logs/YYYY-MM-DD.md` に集約する Stop hook 用スクリプト。 |
| `settings.template.json` | `~/.claude/settings.json` のテンプレート (Stop hook 登録済み)。 |
| `setup-symlinks.sh` | 新しい PC で実行する初期化スクリプト。指示・memory は symlink、scripts は実コピーする。 |

## どこから操作できるか

| 操作場所 | 経路 | 備考 |
|---|---|---|
| 家用PC / 外用PC (Claude Code・Codex) | Google Drive 自動同期 + symlink | `setup-symlinks.sh` 実行後、symlink 越しに常時最新。`git pull/push` も可。 |
| 他PC (git 経由) | `git clone https://github.com/Someru-3321/obsidian-vault.git` | Drive を入れない PC でもここから取得・更新。 |
| **スマホ (Claude アプリ)** | claude.ai/code で `obsidian-vault` repo を開く | 指示を読み書きして commit→push。家PC は次回 pull / Drive 同期で受け取る。 |

## symlink の仕組み (ローカルPC)

| 参照側 (Claude/Codex が見る場所) | 実体 (Vault 内) |
|---|---|
| `~/.claude/CLAUDE.md` | `CLAUDE.md` |
| `~/.claude/projects/<workdir-hash>/memory/` | `memory/` |
| `~/.codex/AGENTS.md` (Codex 入ってる場合のみ) | `AGENTS.md` (Codex 用実ファイル) |

`<workdir-hash>` は Claude Code を実行する作業ディレクトリの絶対パスを、英数字以外を `-` に置換した文字列。デフォルトは Google Drive のマイドライブ直下を想定。

## 別 PC でのセットアップ

```bash
# 1) Google Drive アプリで Vault を同期
#    ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian Vault/ が見える状態にする
# 2) Obsidian を起動し当該 Vault を開いて「作成者を信頼しプラグインを有効化」をクリック
# 3) symlink を張る
bash "$(echo ~/Library/CloudStorage/GoogleDrive-*/マイドライブ/Obsidian\ Vault/00\ Claude\ Instructions/setup-symlinks.sh)"
# 4) git を gh token 経由に (SSH 鍵は未設定。https + gh で push する)
gh auth setup-git
# 5) Claude Code を再起動
```

別ディレクトリで Claude Code を使う場合は `--workdir /path/to/dir` を渡す。

## 同期ワークフロー (両方使う)

- **Drive (自動)**: Obsidian / エディタでこのフォルダを編集 → Google Drive が数秒〜数十秒で他PCへ反映。symlink 越しに常時最新。
- **GitHub (手動・バックアップ兼スマホ経路)**: 区切りのいいタイミングで `git add` → `commit` → `push`。スマホの Claude アプリや Drive 未導入PC はここを操作先にする。
- remote は **https** (`gh auth setup-git` で gh token を使用)。SSH 鍵は未設定なので `git@github.com:...` では push できない。

## 注意点

- **秘密情報を書かない**: Webhook URL、APIキー、銀行口座、パスワード等。Drive と GitHub 両方に乗るので漏洩面が広がる。Private repo でも書かないのが原則。
- **`.gitignore` で除外済みの秘密**: `.obsidian/plugins/*/data.json` (local-rest-api の APIキー含む)、`obsidian-git/.git_credentials_input`。push 前に `git diff --cached --name-only` で混入チェックする習慣を。
- **コンフリクト**: Drive は `*.conflict` ファイル、git は通常の merge conflict。両方を同時に激しく編集しない。基本は Drive を主、GitHub を要所での push に使うと衝突しにくい。
- **ロールバック**: GitHub 履歴で可能 (以前の Drive 一本化時代は不可だった)。`git log` / `git revert` が使える。
- **Codex 固有設定**: `AGENTS.md` は Codex 用の実ファイルで、`CLAUDE.md` と共通ルールを持ちつつ Codex 固有の「接続時の注意」(MCP フォールバック手順) を含む。**`CLAUDE.md` の共通ルールを変えたら `AGENTS.md` の同一箇所も手で揃える** (両者は別実ファイル)。プロジェクト固有指示は各プロジェクトルートに別途 `AGENTS.md` を置く。
