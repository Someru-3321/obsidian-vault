---
name: invoice-email-watcher システム
description: invoice@someru.me に届いた請求書PDFを Apps Script + Claude API + Notion API で自動登録する仕組みの場所と運用
type: project
originSessionId: 4463d90b-ec72-425a-be36-7c04d7987521
---
社内スタッフは請求書PDFを invoice@someru.me に送るだけで、10分以内に Notion DB「請求書申請」へ自動登録される。郵送分はスタッフがスマホで撮影/スキャンして同アドレスへ送る運用で一本化。

- ローカル: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-email-watcher/` (Code.gs, appsscript.json, SETUP.md)
- 稼働場所: Apps Script プロジェクト (invoice@someru.me アカウントで作成、`watchInbox` を 10分トリガー)
- 使うAPI: Claude API (claude-sonnet-4-6, PDF→項目抽出) + Notion API (file upload + page create)
- Script Properties に NOTION_TOKEN と ANTHROPIC_API_KEY を保存
- Gmail ラベル: 処理済み=「Notion登録済み」/ 失敗=「Notion登録失敗」
- Notion 側: 同じ invoice-uploader integration (`ntn_644785540472X...`) を使用

**Why:** これまで「届いた請求書を手動でNotionに転記」していたのを撲滅。社内スタッフ全員がメール添付だけで運用できるようにしたいという要件 (2026-05-11)。

**How to apply:** スタッフ向けには「請求書は invoice@someru.me に送るだけ」と伝えるだけでよい。AI推定の『請求内容』と『部門』は Notion 上で見て必要なら微修正する運用。ローカルからの単発登録は別途 `/invoice-to-notion` スキル経由 (`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-to-notion/submit_invoice.py`)。
