---
name: invoice-email-watcher システム
description: invoice@someru.me に届いた請求書PDFを Apps Script + Claude API + Notion API で自動登録する仕組みの場所と運用
type: project
originSessionId: 4463d90b-ec72-425a-be36-7c04d7987521
---
社内スタッフは請求書PDFを invoice@someru.me に送るだけで、10分以内に Notion DB「請求書申請」へ自動登録される。郵送分はスタッフがスマホで撮影/スキャンして同アドレスへ送る運用で一本化。

- ローカル: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-email-watcher/` (Code.gs, appsscript.json, SETUP.md)
- 稼働場所: **admin@someru.me** の Apps Script プロジェクト (scriptId `1OiTFdtE2cSgh3q7mDMJOkqBKiSdwxkHWaP7AJMWbK5qcYtYW9XpXJcdJ`)。`invoice@someru.me` は admin@ のエイリアス（2026-05-29 ユーザー確認済み。**請求書は invoice@ だけに届く** = この1箱を見れば全請求書を拾える）
- デプロイ: clasp 経由 (`~/.../invoice-email-watcher/.clasp.json`、`clasp login` は admin@ で実施済み)。Monacoへのブラウザ貼付/クリップボード経由は不可だったため clasp push が正解
- 使うAPI: Claude API (claude-sonnet-4-6, PDF→項目抽出) + Notion API (file upload + page create)
- Script Properties に NOTION_TOKEN と ANTHROPIC_API_KEY を保存。**ANTHROPIC_API_KEY は mimi-plus-line-bot と共用**(片方がクレジット切れだと両方止まる)
- Gmail ラベル: 処理済み=「Notion登録済み」/ 失敗=「Notion登録失敗」(admin@ Gmail。受信請求書は「請求書受取」ラベルで人手管理されている)
- Drive バックアップ: `archiveToDrive_` が元データPDFを「請求書受け取り (預かる)」フォルダ (`1bZzFi-mBTi-saZvnIQKgt6qOBGg6d15o`, yuki.watabe@ 所有) に保存。**admin@ に編集者共有が必要**。未共有でも try/catch で握りつぶし Notion 登録は継続
- Notion 側: 同じ invoice-uploader integration (`ntn_644785540472X...`) を使用

**Why:** これまで「届いた請求書を手動でNotionに転記」していたのを撲滅。社内スタッフ全員がメール添付だけで運用できるようにしたいという要件 (2026-05-11)。

**2026-05-29 実態判明と対応:** 当初(2026-05-11)はデプロイ手順を書いただけで **実際には admin@ に未デプロイ**で1件も自動登録されていなかった(「Notion登録済み/失敗」ラベル両方0件、Notion最新が2026-05-10で停止)。この日に clasp で本デプロイ・OAuth認可・Script Properties設定まで完了。テスト実行で **Anthropic クレジット残高不足 (400)** が判明し PDF解析が動かないため、ユーザーの ①Anthropicクレジット追加 ②Driveフォルダの admin@ 共有 待ち。済んだら setupTrigger で10分トリガー有効化 + 「Notion登録失敗」になったイケナカ商事(4月末〆 260430)を再処理。
- 監査メモ: 「請求書受取」ラベルの未登録3件(御影ニット150,000/ライオンシアター154,000/ぴょんちゅーむ91,130)は手動で submit_invoice.py 登録済み。Misoca通知メール(御影/ぴょん)はPDF添付でなくリンク式なので watcher では拾えず、リンク先 `app.misoca.jp/receive_documents/<token>` から「請求書ダウンロード」でPDF取得→登録した。

**How to apply:** スタッフ向けには「請求書は invoice@someru.me に送るだけ」と伝えるだけでよい。AI推定の『請求内容』と『部門』は Notion 上で見て必要なら微修正する運用。ローカルからの単発登録は別途 `/invoice-to-notion` スキル経由 (`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/invoice-to-notion/submit_invoice.py`)。
