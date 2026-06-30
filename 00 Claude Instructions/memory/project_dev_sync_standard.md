---
name: project-dev-sync-standard
description: Claude/Codex×2台のPC で制作物を食い違わせない開発連携標準（GitHub正本＋STATUS.md＋AGENTS.md連携ルール）
metadata: 
  node_type: memory
  type: project
  originSessionId: 216c12b4-088b-419d-8f01-efe50a965c3c
---

ユーザーは **Claude と Codex の両方**を、**家用PCと外用PCの2台**で使う。2026-06-12 に「Claude(Google Drive)とCodex(日付フォルダ)が別場所で作業し、同じ依頼で別物に書き換わる」事故が起きたため、2026-06-13 に恒久対策の連携標準を導入した。[[project-booking-portal]] が発端。[[project-obsidian-vault-sync]] と同じ GitHub 同期方式。

**連携標準（全主要プロジェクト共通）**
- **正本 = GitHub Private リポジトリ（`Someru-3321/<name>`）**。ローカル（DriveでもCodex日付フォルダでも）は作業コピーにすぎない。
- 各repoに **`STATUS.md`**（現状／次やること／最終更新ツール・PC・更新ログ）。着手前に読み、完了後に更新してpush。
- 連携ルールを **`AGENTS.md`（Codex）に明記、`CLAUDE.md` は `@AGENTS.md` で読込**（Claudeも従う）。中身=「着手前pull→STATUS確認／既存尊重・作り直さない・独自コピー増やさない／完了後STATUS更新→commit→push／壊れたら再clone」。デプロイ手順はrepo固有なので連携ブロックには含めない。
- 他PCは `git clone https://github.com/Someru-3321/<name>.git ~/dev/<name>`。以後 pull→作業→push。

**2026-06-13 時点で連携基盤を入れた7リポジトリ（全てPrivate）**: booking-portal / talent-portal / mimi-anken-kanri / rental-form-vercel / mimi-web / mimi-plus-web / mimi-admin。mimi-anken-kanri・mimi-admin は新規GitHub化。rental-form-vercel・mimi-web は当初PUBLICだったのでPrivateに変更。mimi-web/mimi-plus-web は remote を SSH→https に切替（gh tokenで確実にpush）。

**運用上の罠（実体験）**
- Drive内クローンは GitHub より遅れることがある（mimi-plus-web は4コミット遅れてた）。push前に必ず `git pull`/`fetch`。
- **コミット前に必ずブランチ確認**: talent-portal を別セッションが `fix/bugfixes-batch` で作業中で、そのブランチに連携コミットが乗った（mainには未反映、マージ時に入る）。`git -C <repo> branch --show-current` で確認し、稼働中の別セッション/ブランチには割り込まない。
- 同じrepoで複数のgit操作を**並行（バックグラウンド）で走らせない**。ref lock衝突・stale ref誤判定が起きる。順次実行する。
