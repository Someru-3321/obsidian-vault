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

**重要な制約（2026-05-13判明）**:
- GMOあおぞらの「振込入金がありました」メールはプライバシー仕様で本文に**口座番号・金額・振込人名を含まない**。日時のみ。
- そのため口座番号フィルタは無効化済み（Code.gsは全入金通知メールでSlack通知する仕様に変更）。
- Notion自動更新も不可（マッチに必要な情報がない）。代わりに**Slack通知に未支払予約リスト（上位10件）を含める**仕様。ユーザーはSlackで該当予約を目視で識別 → Notion リンクから「支払【済】」を手動チェック。
- Apps Scriptトリガーは**4時間ごと**＋ **watchDeposits 関数内で JST 22:00-07:59 をスキップ**するロジック付き。実質 08:00-22:00 帯のみ 1日4回前後動作（深夜の Slack 通知を避ける運用）。
- **本番API利用申込中**（2026-05-13、open-api@gmo-aozora.com宛にメール送信）。承認後にOAuth2実装で振込人・金額の自動取得が可能になる予定。sunabarはサンドボックスで実口座データは触れない。

**初回構築時の状況**（2026-05-13時点）:
- ✅ Slack Webhook作成、Apps Script デプロイ、トリガー登録、メール宛先変更、Notion接続すべて完了
- ✅ ANTHROPIC_API_KEY は未設定（user未保有）。コードはregexフォールバックモードで動作中。
- 🟡 本番API承認待ち（1〜2週間スパン）
