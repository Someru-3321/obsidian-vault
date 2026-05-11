---
name: gmo-deposit-watcher project
description: GMOあおぞら mi-mi plus口座(2439067)入金通知をSlack転送+Notion「出入管理表【mi-mi +】」DBの「支払【済】」checkboxを自動更新するApps Script
type: project
originSessionId: 317da2d1-454f-404c-9d6c-c29abd54c311
---
`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/gmo-deposit-watcher/`

GMOあおぞらネット銀行から `payment@someru.me` (admin@のエイリアス) に届く振込入金通知を:
1. 口座 `2439067`（mi-mi plus）への入金だけ抽出
2. Notion「出入管理表【mi-mi +】」DB (data_source_id: `65072907-b89f-41a9-98d7-4aeeacfe0322`) で 振込人 ↔ ご予約名 が一致するレコードを検索
3. 絞込: 決済方法=お振込 AND 支払【済】=false
4. 1件マッチ → 「支払【済】」(checkbox)をtrueに更新
5. Slackに結果通知（完了/未マッチ/複数ヒットを区別）

**Why**: mi-mi+ レンタル予約の入金確認を手動で行っていたものを自動化。GMOあおぞらの標準メール通知は口座別フィルタができないので、Apps Script側で `2439067` で絞る。

**How to apply**:
- 「支払【済】」プロパティは出入管理表【mi-mi +】DBにのみ存在（請求書申請DBには無い、初期は混同していた）
- マッチングは Claude API (claude-sonnet-4-6) ベース。漢字↔カナ・姓のみ一致を Claude が判定
- 信頼度閾値 0.75 以上で自動更新。それ未満は Slack に候補リンクのみ通知して手動確認に
- 金額照合は未実装（DBに総額プロパティが無いため）。名前マッチに統一
- Slack Webhook URL は Apps Script の Script Properties (`SLACK_WEBHOOK_URL`) に保存（このファイルには載せない）
- invoice-email-watcher と同じ Notion トークン + ANTHROPIC_API_KEY を使用

**初回構築時の未完了タスク**（2026-05-12時点）:
1. ✅ Slack Webhook作成
2. 銀行のメール通知宛先を `invoice@someru.me` → `payment@someru.me` に変更（GMOあおぞら設定で）
3. payment@ は admin@someru.me のエイリアス（確認済み） → Apps Scriptは admin@ で作成
4. Apps Script デプロイ + Script Properties（SLACK_WEBHOOK_URL, NOTION_TOKEN, ANTHROPIC_API_KEY）設定
5. Notion「出入管理表【mi-mi +】」DBにinvoice-email-watcherインテグレーションを接続
6. 実メール到着後、Claudeプロンプトに実フォーマット例を追加するとさらに精度向上
