---
name: contract-sign-watcher project
description: クラウドサイン/MFクラウド契約 から accounting@someru.me に届く合意締結完了メールをSlack転送+Notion「同意 【済】」自動更新するApps Script
type: project
originSessionId: 317da2d1-454f-404c-9d6c-c29abd54c311
---
`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/contract-sign-watcher/`

クラウドサイン (`support@cloudsign.jp`) / マネーフォワードクラウド契約 (`*.moneyforward.com`) から `accounting@someru.me` (yuki.watabe@ のエイリアス) に届く「合意締結が完了しました」メールを:
1. 送信元 + 「合意締結が完了」など完了通知ワードでフィルタ
2. 件名 `「[書類名]」の合意締結が完了しました` または 本文 `書類タイトル：xxx` から書類タイトル抽出
3. Notion「出入管理表【mi-mi +】」DB (`3f665e5e-c573-4bcd-bbbf-60a11a6d3583`) で 同意 【済】=false の予約を取得
4. 書類タイトル ↔ ご予約名 を照合 (regexまたはClaude API)
5. 信頼度0.75以上で「同意 【済】」を true に更新
6. Slackに整形通知 (マッチ成功/未マッチ/低信頼度を区別)

**Why**: mi-mi+ レンタル契約の同意書締結確認を手動で行っていたものを自動化。クラウドサインの完了メールはNotionと連携できないので、Apps Script + Notion API で同期。

**重要な構成**:
- **Apps Script は yuki.watabe@someru.me (/u/0) アカウント配下**。admin@someru.me ではない。`accounting@` は yuki.watabe@ のエイリアスのため、yuki.watabe@ の Gmail に届く。
- gmo-deposit-watcher は admin@someru.me 配下なので、Notion 統合は同じトークンでも別アカウント。
- Apps Script ID: `1srMMjfs_cF4AH1XXJWgTlHvKYJlZNn0HwvRTAnpvKTPEFInZwlOyCac2`
- URL: `https://script.google.com/u/0/home/projects/1srMMjfs_cF4AH1XXJWgTlHvKYJlZNn0HwvRTAnpvKTPEFInZwlOyCac2/edit`

**Code.gs の主要関数**:
- `watchSignings()`: トリガー本体。Gmail検索 → 各メール処理 → ラベル付与。JST 22:00-07:59 はスキップ。
- `processMessage_(msg)`: 送信元+完了ワード判定 → 書類タイトル抽出 → Notion候補取得 → マッチング → Slack通知
- `extractDocumentTitle_(subject, body)`: 「...」の合意締結が完了 や 書類タイトル: xxx から抽出
- `matchByRegex_(title, candidates)`: 簡易regex照合 (Claude APIキー無しのフォールバック)
- `askClaudeToMatchTitle_(...)`: Claude API 経由の高精度マッチング (要 ANTHROPIC_API_KEY)
- `fetchPendingConsentReservations_()`: Notion DBから 同意 【済】=false を取得
- `updateNotionConsent_(pageId)`: 「同意 【済】」を true に更新

**設定値**:
- Script Properties: `SLACK_WEBHOOK_URL`, `NOTION_TOKEN` (gmo-deposit-watcher と同じ値を再利用)
- ANTHROPIC_API_KEY: 未設定（regexフォールバック動作中）
- トリガー: `watchSignings` 4時間おき (時間ベースのタイマー)
- Gmail検索: `deliveredto:accounting@someru.me (from:cloudsign.jp OR from:bengo4.com OR from:moneyforward.com) newer_than:30d`

**初回構築時の状況**（2026-05-13）:
- ✅ Code.gs デプロイ済み
- ✅ Script Properties 設定済み (NOTION_TOKEN/SLACK_WEBHOOK_URL)
- ✅ 時間トリガー登録済み (4時間おき)
- ✅ OAuth 権限承認済み (Gmail/UrlFetch)
- ✅ watchSignings テスト実行成功（過去30日に accounting@ 着の CloudSign メール無しのためログ出力なし）
- 🟡 実メールでの動作確認は次回 CloudSign 締結時

**注意点**:
- 同じ Notion Integration トークンを admin@ の gmo-deposit-watcher と yuki.watabe@ の contract-sign-watcher で共有しているが、Apps Script が異なる Google アカウント配下にあるので OAuth は別途必要。
- mi-mi+ レンタル契約で実際に CloudSign が使われた履歴はまだ少ない（過去はWithLIVE等の業務提携契約が中心）。本格運用前にレンタル用の同意書テンプレを CloudSign で作成しておく必要あり。
- 書類タイトルに予約名がそのまま含まれることを前提とした照合。書類タイトルが汎用名（例: 「mi-mi+ 同意書」のみ）になると照合不可。
