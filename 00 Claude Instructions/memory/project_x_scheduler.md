---
name: project-x-scheduler
description: X/Instagram 予約投稿+自動リプツール(社内)。Next.js+Vercel+Supabase+Claude。X側完成・ビルドgreen、デプロイ待ち
metadata: 
  node_type: memory
  type: project
  originSessionId: 2b5658c0-ac51-441d-ba33-716a38de61c7
---

`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/x-scheduler/`

X(Twitter)と Instagram の予約投稿 + 自動リプ/コメントを1ページで管理する社内ツール。対象3アカウント: @saihate_idol / @someru_inc / @mi_mi_someru(X・IG とも自社所有)。動機=公式予約だとリプ予約できない/画像にアカウント載せられない。

## 核心の制約(調査済み・[[x-scheduler-photo-tagging]] 参照)
- **X API は写真へのアカウントタグ付け非対応** → リプに @アカウントを載せる方式で代替。
- **Instagram は自社アカウントのみなら Meta 審査不要(Standard Access)**。しかも IG は user_tags で写真タグ可能。
- X 投稿コスト=従量 $0.01/件。

## 構成
- Next.js(App Router)+Vercel+Supabase(channels/posts/post_replies、media バケット)+Claude(下書き)。
- 認証 X=OAuth2 PKCE(`tweet.write users.read media.write offline.access`、トークン自動更新)。IG=FB Login 長期トークン(未実装)。
- スケジューラ=GAS タイムトリガー→`/api/cron/run?secret=`を毎分(Vercel無料cronは1日1回なので)。
- 管理画面=ADMIN_TOKEN の簡易Cookie認証。

## 状態(2026-06-15)
- **X側 完成（予約投稿+自動リプ+伸び分析）・`next build` green・ログイン画面描画確認済み**。デプロイ未。
- 伸び分析: public_metrics(インプレ等)をアカウント別中央値で「伸びた/ふつう/伸びてない」相対判定。指標更新は従量課金($0.005/読取)のため GAS で1時間ごと・直近14日のみ。
- **Supabase 構築完了**: project ref=qpplphjjpgprmzxjnrnb(Tokyo)、schema投入、mediaバケット、service_role権限付与、接続検証OK。URL/key は `.env`。
- **X 構築完了**: 開発者オンボーディング(someru-x-scheduler,pay-per-use)、アプリ33071225 OAuth2(Read+write/WebApp,callback=localhost:3200)、Client ID=Q01aNklheFQ0YXhYeHRSd2VfdEQ6MTpjaQ。dev垢=@saihate_idol。`.env`に全値。
- **ローカル疎通テスト全部OK**(ログイン/@saihate_idol OAuth接続/予約/cron発火)。
- **本番動作確認済み**: ユキが$5クレジット投入→@saihate_idolに本文＋自動リプを実投稿成功→両ツイート削除済み。投稿/自動リプ機能はライブで動く。(pay-per-useはクレジット必須＝残高切れると402。課金は当方不可)
- 既知の罠: Supabaseに貼ったschemaで channels.x_user_id を書き落とし→alterで追加済(ファイルは正)。
- **Vercel本番デプロイ済**: https://x-scheduler-phi.vercel.app (someru-3321s-projects/x-scheduler)。env全投入・本番callback登録・稼働確認済。管理トークンはローカル.env参照。
- **GAS自動実行 完了**: Apps Script「x-scheduler-cron」(yuki.watabe@)。runScheduler毎分/runMetrics毎時 稼働中(疎通0%エラー)。→ @saihate_idol は完全自動運用可能。
- **画像投稿 完成・本番動作確認済み**: /api/upload→Supabase media→X v2 media upload→ツイート添付(最大4枚)。実テストで画像付き投稿成功→削除。403懸念は解消。
- **3垢とも接続完了(2026-06-16)**: @saihate_idol/@mi_mi_someru/@someru_inc を channels に保存済(/api/channelsで確認)。admin@someru.me プロファイルに3垢ログイン済→認可ページのアカウント切替で各々「アプリにアクセスを許可」を実行。罠=x.com OAuth認可ページが時々 ERR_TOO_MANY_REDIRECTS でループ(一時的cookie/セッション状態)→対処は先に /api/login してから /api/x/connect を開き直すとクリーンに出る。残りは Instagram と Anthropic key任意(AI下書き)。
- **v2 精度向上(2026-06-16)**: 分析=エンゲージ率中央値×画像有無バケットで相対判定＋判定理由note(lib/metrics)、AI分析 lib/insights+/api/insights(時間帯/曜日/長さ別集計→Claudeで示唆)。下書き=lib/brand(アカウント別ブランド)＋伸びた投稿few-shot＋3案生成(lib/draft.generateDrafts,/api/draft)、lib/textlen(X重み付き文字数)。UIに3案ピッカー/文字数/AI分析。next build green。**AI機能はANTHROPIC_API_KEY必須=現状未設定(Vercelに要追加)**。
- 残課題: v2 media upload の OAuth2 疎通は初回要確認。
- 詳細な進捗は同フォルダ STATUS.md が正。連携は [[project_dev_sync_standard]] 方式(GitHub Private正本化はこれから)。
