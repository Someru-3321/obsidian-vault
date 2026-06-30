---
name: project-talent-portal
description: 染める inc. タレントポータル (Next.js 16/Notion)。リポジトリ場所・本番URL・アーキ・改善ロードマップ
metadata: 
  node_type: memory
  type: project
  originSessionId: c8411ad4-c80d-480b-9675-905c34a2fa3c
---

染める inc. の**タレントポータル**。タレント本人がスマホでログインし、SNSの伸び・ライブ実績(チェキ集計)・報酬見込み・月次コーチングを見て、集計を自己報告するシステム。最終形は「権限付与されたタレントが自分のスマホで閲覧+報告」。目的=タレントが「もっとSNS更新/配信頑張ろう」と思えるモチベ装置にする。

**場所(2026-06-13 整備):**
- ローカル正本: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/talent-portal`
- GitHub: `Someru-3321/talent-portal` (Private)。`git push` で Vercel 本番に自動デプロイ(連携済)
- 本番: https://talent-portal-five.vercel.app/portal (Vercel project `talent-portal`, prj_a6mM1tIWuVVXvfrc0AErgJYFTSjb)
- 元は OpenAI Codex 作業フォルダ `~/Documents/Codex/2026-06-12/.../deployed-source` にあったのを移管(Vite版の古いコピーは無視)
- dev: 作業ルート `.claude/launch.json` の `talent-portal`(port 3100, `npm run dev`)。プレビューはこれで起動

**アーキ:** Next.js 16(App Router/Turbopack, React 19, recharts, lucide-react)。Notion バックエンド。`src/proxy.ts`=Next16でmiddlewareがリネームされた新仕様。`AGENTS.md`が「コード書く前に node_modules/next/dist/docs を読め」と警告(訓練データと違う破壊的変更あり)。

**主要ルート:** `/login`, `/portal`(ダッシュボード1468行の巨大ファイル), `/portal/report`(集計報告), `/portal/report/edit`, `/portal/rewards`, `/portal/coaching`, `/portal/coaching/meetings`, `/portal/admin`(管理画面=実在。`/admin`ではない), `/privacy`, `/terms`。API: x/instagram/streaming/group/reports/coaching/admin/auth/tiktok + cron(x-snapshots, streaming-snapshots)。

**Notion 3DB(作成済・5人投入済):** タレント一覧 `6ae7f016a9da4289ba80fa131c151cc4` / コーチング `e7e77aa314ca4b5b8286d186f809568f` / 集計報告 `1aef0338a7bf804f9969d6f2ea69a12e`。詳細スキーマは repo の `SETUP.md`。

**本番env状況(2026-06-13時点、.env.production.local より):** SESSION_SECRET/NOTION_TOKEN/Notion3DB/X_BEARER_TOKEN は設定済。Instagram(ACCESS_TOKEN/APP_USER_ID)・TikTok・配信は未設定。なのに本番UIは X/コーチング等が「確認中」表示=トークン無効 or 旧デプロイの疑い→API連動フェーズで要調査。ローカルdevは `.env.local` に VERCEL_OIDC_TOKEN しか無く全部デモ表示。

**進め方(ユーザー方針):** ①まずシステム改善(モバイル最適化・モチベ機能・UXバグ修正)→ ②その後 API連動。

**既知の改善ポイント:** 報酬「月別推移」グラフが空(描画バグ)/報告履歴の現場名欄にメモが混入(入力UX問題)/グループ合計が月境界でズレてる疑い/管理画面の分析機能が薄い。

関連: [[project-saihate-brand-info]](最果てのハイライト5人) [[user-github]] [[project-obsidian-vault-sync]]
