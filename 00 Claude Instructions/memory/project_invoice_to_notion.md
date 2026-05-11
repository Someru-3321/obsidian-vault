---
name: invoice-to-notion システム
description: 請求書PDFをNotion「請求書申請」DBに自動登録するスキル一式の場所と運用ルール
type: project
originSessionId: 4463d90b-ec72-425a-be36-7c04d7987521
---
請求書PDFをチャットに添付すると、Claudeが項目抽出→Notion DB「請求書申請」(`252f0338a7bf8051bf45dbff280cd667`) にページを作成する。PDF本体も「請求書」プロパティに添付される。

- スキル: `~/.claude/skills/invoice-to-notion/SKILL.md`（トリガー名 `invoice-to-notion`）
- 実行スクリプト: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-to-notion/submit_invoice.py`
- 認証: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/payment-check/.env` の `NOTION_TOKEN` を共用（同じインテグレーション）
- Notion data_source_id: `252f0338-a7bf-80d9-abee-000be8645739`

**Why:** 染める inc. の請求書登録を毎回手入力していたのを自動化。`請求内容`（プロジェクト説明テキスト）と `部門`（mi-mi / 染める inc.(全体) / 最果てのハイライト / ミミメイド / メンズアイドル のselect）は PDFに書かれていないことが多く必ずユーザー確認が必要 — これが「プロジェクトの内容も必ず入れて欲しい」という要求の趣旨。

**How to apply:** ユーザーが請求書PDFを添付したら invoice-to-notion スキルを起動。ステータスは空のまま登録し、Notion側で手動で「申請中」等に設定する運用。初回セットアップは `cd ~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-to-notion && pip install -e .`。
