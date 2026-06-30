---
name: project-saihate-offer-mailer
description: Notionアイドルリストのボタン → Apps Script Web App → Gmail下書き作成 (saihate@someru.meエイリアスFrom) のオファー送信補助システム。2026-05-20構築。
metadata: 
  node_type: memory
  type: project
  originSessionId: d0ee4323-950e-47ce-8411-f266e1031ad3
---

# saihate-offer-mailer

Notion「アイドルリスト」DB行のButtonを押すと、Apps Script Web App経由でGmail下書きが saihate@someru.me 名義で自動作成され、下書き画面にリダイレクトされるシステム。

**ローカル**: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/saihate-offer-mailer/`

**Notion DB**: アイドルリスト (data_source_id `46ece7ed-2e18-4dd4-bbd3-c0fd5bb07c70`、DB URL `https://www.notion.so/55a5f085284f410599a04a089758e65e`)

**読むプロパティ**: `オファー文章` (rich_text, `<br>`を改行に変換) / `件名` (rich_text, 空ならデフォルト件名) / `担当者メールアドレス` (rich_text or email) / `グループ名` (title)

**追加した DB プロパティ (2026-05-20)**:
- `件名` (Text) ← Apps Scriptがここから読む
- 未追加 (デプロイ後): `Draft URL` (Formula) と `下書き作成` (Button)。Buttonは Open link で Formula を参照

**Apps Script実行**: entertainment@someru.me (saihate@someru.me が entertainment@someru.me の Gmail エイリアスとして登録されているため。admin@someru.me ではない)。Web Appのアクセスは「自分のみ」。Script Properties: `NOTION_TOKEN` (新規 `saihate-offer-mailer` Notion インテグレーション)、`FROM_ALIAS` (省略時 saihate@someru.me)。

**送信元プロパティ (2026-05-20追加)**: Notion DB の `送信元` (Select、選択肢 saihate@someru.me) で行ごとに From切替可。entertainment@someru.me のGmailエイリアスとして登録されているアドレスのみ追加可能。

**Why**: ライブ出演オファーをアイドル単位で個別カスタマイズ済みの文章で送る運用で、mailto は文字数制限+Fromエイリアス指定不可で限界、Gmail Compose URLもFromアドレス指定不可。Apps Script + Gmail API なら from エイリアス確実+文字数無制限+下書きで誤送信防止。

**How to apply**: アイドルリストDBで新しいグループにオファーを出す時はこのフローで下書き作成。送信は必ず本人が下書き画面で確認後に手動。即送信モードは実装していない。
