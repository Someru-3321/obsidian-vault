---
name: project-booking-portal
description: アイドルブッキングポータル(Next.js)の正本GitHubリポジトリ・Claude/Codex/2PC連携ルール・デプロイ手順・Sensitive env の罠
metadata: 
  node_type: memory
  type: project
  originSessionId: 0583be14-1009-41b0-8871-1e4916f48d13
---

アイドル ブッキングポータル = 本番 https://booking-portal-xi.vercel.app/ （社内用。Notion アイドルDB読込→イベント日程ごとの候補仕分け・AI推薦・オファーDM/メール/LINE・Resend送信・Notionステータス更新）。Next.js 16 + React 19 + @notionhq + @anthropic-ai/sdk + resend。

- **正本(唯一の真実) = GitHub Private `Someru-3321/booking-portal`（main）**。2026-06-13 に GitHub 正本化。Claude も Codex も 2台のPCも、着手前 `git pull`／完了後 `git push`、`STATUS.md` を読む・書く。連携ルールは repo の `AGENTS.md`（`CLAUDE.md`が`@AGENTS.md`で読込）に明記済み。「同じ依頼でも作り直さない・日付フォルダで独自コピーを増やさない」。これは2026-06-12に Claude(Drive)とCodex(日付フォルダ)が別場所で作業し別物に書き換わった事故への恒久対策。[[project-obsidian-vault-sync]] と同じGitHub同期方式。
- **旧複製の退避**: 食い違いコピー4つを `~/Documents/Codex/_archive_old_booking_20260613/` へ退避済み(削除可)。正本以外は触らない。
- **ローカル作業コピー**: `~/Documents/Codex/2026-06-13/codex-https-booking-portal-xi-vercel/work/booking-portal-src`（このMacの現クローン。Google Drive maindrive ではない）。他PCは `git clone https://github.com/Someru-3321/booking-portal.git ~/dev/booking-portal`。Vercel project = `booking-portal`（projectId `prj_aU6oGSmbEuEZZSmm8P69b950yllH`, org `team_2PIk2ZVdKE9yR3T9Mzm84UD9`）。baseline commit `21ccc16`。
- **デプロイ**: このMacは `npx vercel` が `someru-3321` で認証済み（auth は `~/.vercel` でなく macOS app-support）。本番反映は当該ディレクトリで `npx vercel deploy --prod --yes` のみ。AGENTS.md の `/Users/watanabeyuuki/Desktop/booking-portal` は Codexクラウドのユーザー名で、実体はこのローカルのリンク済みディレクトリ。「別の中途半端なディレクトリをリンクしてデプロイ」すると過去に本番全404になったので、必ずこのリンク済みディレクトリから。
- **Sensitive env の罠**: `NOTION_TOKEN` 等は Vercel側で Sensitive 設定のため `vercel pull` しても値が空で降りてくる→**ローカルやプレビュー(`vercel deploy`)では本番ビルドを再現できない**（page data 収集で `NOTION_TOKEN is required` 等が出る。コードのバグではない）。クラウドの**本番**ビルド(`--prod`)だけが実値注入で通る。ローカルで `npm run build` を通したいだけなら全キーにダミー値の `.env.local` を置けばOK（gitignore済）。
- **検証**: デプロイ後 `curl -s https://booking-portal-xi.vercel.app/api/email` が JSON 200・トップが 200 ならOK（AGENTS.md準拠）。問題時は `npx vercel rollback` で直前の本番デプロイへ。
- 全部 Codex(AI)任せで運用してきた経緯。ユーザー本人はデプロイ機構を把握していない前提で動く。
- 改修ノート: Obsidian `~/Documents/Obsidian Vault/Projects/booking-portal.md`。
