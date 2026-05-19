---
name: rental-deadline-watcher project
description: mi-mi+ レンタル予約で前日朝9時に「締結待ち」「契約済 郵送待ち」のままの予約をSlack通知するApps Script
type: project
originSessionId: 612cabbd-829e-4356-87e0-4053d44a2b5b
---
`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/rental-deadline-watcher/`

Notion「出入管理表【mi-mi +】」DB (data_source: `65072907-b89f-41a9-98d7-4aeeacfe0322`) を毎朝 JST 09:00 にチェックし、**翌日がレンタル日 (date.start) かつ ステータス が「締結待ち」「契約済 郵送待ち」のいずれか** の予約を Slack に通知する。

**Why**: レンタル前日になっても契約締結や郵送が未完了の予約を見落とすリスクがあったため。

**How to apply**:
- Apps Script は **yuki.watabe@someru.me 配下** (contract-sign-watcher と同じアカウント)
- 通知先 Slack チャンネルは新規 Webhook (gmo/contract のものとは別)
- Notion 統合トークンは contract-sign-watcher と同じものを Script Properties にコピー流用
- 通知対象ステータスを増やしたい場合は `Code.gs` の `PENDING_STATUSES` 配列を編集

**ファイル構成**:
- `Code.gs` — 主要関数: `checkPendingRentals` (トリガー本体), `fetchPendingTomorrowRentals_`, `notifySlack_`, `setupTrigger`, テスト用 `testNotionFetch` / `testSlackPost` / `testRunOnce`
- `appsscript.json` — timeZone=Asia/Tokyo, スコープ: script.external_request + script.scriptapp
- `SETUP.md` — Slack Webhook 発行 → Apps Script 作成 → Script Properties → トリガー登録の手順

**Notion API**:
- エンドポイント: `POST https://api.notion.com/v1/data_sources/65072907-b89f-41a9-98d7-4aeeacfe0322/query` (新エンドポイント; contract-sign-watcher は旧 `/v1/databases/.../query` を使っているが、こちらは新型を採用)
- **`Notion-Version: 2025-09-03` が必須** (`2022-06-28` だと `/data_sources/` エンドポイントは `Invalid request URL` 400 になる)
- filter: `AND [ レンタル日.date.equals = 明日YMD, OR [ ステータス.status.equals = 締結待ち, = 契約済 郵送待ち ] ]`
- 明日のJST日付は `Utilities.formatDate(addDays(today, 1), 'Asia/Tokyo', 'yyyy-MM-dd')` で生成

**トリガー**: `setupTrigger` を実行すると `checkPendingRentals` が毎日 JST 09:00-10:00 帯に実行される (`atHour(9).everyDays(1).inTimezone('Asia/Tokyo')`)。

**初回構築時の状況** (2026-05-15):
- ✅ ローカルにファイル作成完了 (Code.gs / appsscript.json / SETUP.md)
- ✅ Apps Script プロジェクト作成済み (script ID: `1Zs62gPXy-OPx1PN2clKWG8I7Y957se4VVJXiNuaQJVzYYT5TYHYLh8s0`、yuki.watabe@配下)
- ✅ Code.gs 投入・Script Properties (NOTION_TOKEN + SLACK_WEBHOOK_URL = contract-sign-watcher と同じチャンネル) 設定
- ✅ OAuth 承認・setupTrigger 実行・JST 09:00 トリガー登録
- ✅ testRunOnce 動作確認 (Notion 該当0件で正常終了)
- 🟡 testSlackPost (Slackへの実通知テスト) は未実行 — Apps Script GUI の関数選択ドロップダウンがブラウザ操作で正確に切り替わらず testRunOnce が再実行される問題があったため。実通知の確認は手動 or 実運用日待ち
