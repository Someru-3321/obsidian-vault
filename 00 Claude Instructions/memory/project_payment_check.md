---
name: 入金照合の運用手順 (1件ずつブラウザ確認)
description: 染める株式会社の Notion 案件1件を MF請求書 + MF会計(SMBC) で確認する具体的な手順。Claude Code が Chrome MCP で実行する。
type: project
originSessionId: 2ee1d04b-0cd5-42ff-9be3-9657df7eb839
---
ユーザーは Notion 案件ページの URL を1件ずつ送ってきて、Claude Code に「入金確認して」と依頼するスタイル。Python スクリプトではなく Chrome MCP でブラウザを操作してその場で確認する運用。

**Why:** Notion で「完了/着地金催促」等になっている案件が、MF 請求書側で本当に入金チェック(未入金タグ)が外れているか、MF 会計の SMBC 法人口座に着金しているかを毎回確認する必要があるため。ミスは許されない。

**How to apply (毎回の手順):**

1. **Notion 案件ページを取得**: `mcp__5978d8d9-..._notion-fetch` でユーザーの URL を fetch。`プロジェクト名` / `請求管理` / `進行状況` / `グループ` / `着数` を控える。

2. **MF 請求書で対応する請求書を特定**:
   - https://invoice.moneyforward.com/billings を開く（要 Chrome MCP / Browser 1 などログイン済みブラウザ）
   - DOM パース用 JS:
     ```js
     const cbs = Array.from(document.querySelectorAll('input[type="checkbox"]'));
     // each row: 日付 / 【No. 請求書 XXXX】/ 取引先名 案件名 / 状態 / サブ状態 / 金額
     ```
   - 全4ページあり (392件規模)。プロジェクト名のユニーク部分でマッチ。
   - 状態系: `下書き` / `送付済み` / `受領済み` (主) と `入金済` / `未入金` / `DL済み` / `郵送済み` (サブ)
   - **「入金済」サブ状態 = 支払い済みの「チェック」。それ以外なら未入金疑い。**

3. **未入金疑いなら MF 会計で SMBC を確認**:
   - https://accounting.moneyforward.com/books/receipt_journal (現預金出納帳)
   - フィルタ: 勘定科目=現金及び預金, 金額=請求金額ぴったり, 期間=請求書発行日以降
   - ヒットゼロなら摘要欄に振込元名カナ(例: 取引先の頭文字数文字、人名のカナ)を入れて再検索
   - それでもゼロなら **真の未入金**。Notion の状況メモも合わせて報告

4. **判定の出し方**:
   - Notion=完了/処理済/売掛 かつ MF=入金済 → ✅ 整合
   - Notion=完了 かつ MF=未入金 → 🚨 要調査 (Notion か MF どちらかが古い)
   - Notion=着地金催促/納品後共有済 かつ MF=未入金 かつ SMBC着金なし → 🚨 真の未入金、要催促
   - SMBC着金あるが MF=未入金 → ⚠️ 同期漏れ、MF側で消込必要

**重要な注意:**
- 振込元名は「GMG entertainment」のような英字法人名でも、実際の振込明細はカナ表記（「ジーエムジー」「カ）GMG」「担当者個人名」など）になることが多い。1パターンでヒットしないからといって即「未入金」と決めず、複数のカナバリエーションで試す。
- 振込手数料が引かれて着金するケースもあるので、ピッタリの金額でゼロなら範囲指定 (±1500円) でも検索する。
- 銀行口座は SMBC 法人 (主)・SMBC (個人?)・【法人】三井住友銀行・楽天銀行・GMOあおぞら 等複数あり。SMBC法人がメインの振込先だが、念のため全現預金で検索する。

**Notion DB 情報:**
- DB ID: `d376b2247feb4cfebd18cdd5f82fc73e` (🎀 プロジェクト)
- 請求管理ビュー: `?v=215f0338a7bf80a9a4c4000c2d3dd780`
- 主要プロパティ: プロジェクト名 / 請求管理 (status) / 進行状況 / グループ / 着数 / 状況メモ

**廃止した方針:**
~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/payment-check/ に Python の OAuth スクリプト一式を置いたが、ユーザーは Claude Code 上で都度ブラウザ確認したかったので未使用。ファイルは削除候補（残してもOK、ユーザーに確認してから判断）。
