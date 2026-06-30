---
name: project-saihate-youtube
description: 最果てのハイライトのYouTubeチャンネル@saihate_idolはentertainment@someru.me配下。予約投稿/コミュニティ投稿の手順とアカウント注意
metadata: 
  node_type: memory
  type: project
  originSessionId: 5557fdbe-7439-4de3-ac47-dd3d35b8d68a
---

最果てのハイライトのYouTubeチャンネルは **@saihate_idol**（チャンネルID `UCAbBJFYoQ7F1weyZuO_hpFg`、登録者約748人・動画18本／2026-06時点）。

- ログインは **entertainment@someru.me** のGoogleアカウントから管理するブランドチャンネル（2026-06の予約投稿作業で確認。以前 admin 管理と記録していたが誤り）。なお配信系の [[project_saihate_streaming_artist_accounts]]・[[project_bandsintown]] は **admin@someru.me** 配下で、YouTubeとは管理アカウントが異なるので混同しないこと。投稿前にアバター→「アカウントを切り替える」で最果てのハイライト(@saihate_idol)に切り替えること（既定では個人垢「ゆき @ゆき-c4u3b」が選ばれていることがある）。
- コミュニティ投稿の作り方: YouTube右上「+作成」→「投稿を作成」。公開設定はデフォルト「公開」。文面入力後、composer右下の青い「投稿」ボタンで即公開。
- 投稿文は Chrome MCP の `type` で絵文字(🦋等)・罫線・改行とも問題なく入力できた。

## ライブ映像Shortの予約投稿（2026-06 実施）

2026/05/30 大阪ライブのShortを7本、6/4〜6/26に各21:00で予約（[[project_saihate_brand_info]]「敗北者」リリースツアー）。NLS short1=6/8・short2=6/16・short3=6/26 を新規追加、未明3本とshort4は既存。手順と注意:

- **アップロード**: encodeフォルダはMCPセッション共有外のため `file_upload` 不可。ユーザーに動画ファイルの手動D&Dを依頼する。
- **予約フロー**: 右上「+作成」→「動画をアップロード」→ 詳細(タイトル/概要)→ 視聴者層「いいえ、子ども向けではありません」(必須)→「次へ」×3 → 公開設定 →「スケジュールを設定」展開 → 日付カレンダー+時刻テキスト欄(クリック→cmd+a→"21:00"→Return)→「スケジュールを設定」ボタンで確定。確定後ダイアログに「○月○日 21:00 に公開」と出る。一覧反映はラグがありcmd+rで最新化。
- **ハッシュタグ化けバグ**: 概要欄でハッシュタグの直後に改行すると、YouTubeの候補ドロップダウンが先頭候補を確定して別タグに化ける(#Shorts→#idol等)。**タグ行は概要欄の末尾に置き、打ち終わったらEscapeで候補を消す**と化けない。
- **タイトル誤入力バグ**: タイトル入力直後に概要を打つとフォーカスがタイトルに残り概要がタイトル欄に入る。Escape後に概要欄を明示クリックしてから入力する。
- **概要欄テンプレ(ライブShort)**: 先頭に楽曲配信告知+linkco.reリンク → ライブ情報(日付/ツアー名/曲名) → -SNS-(公式X/MUSIC) → -member-(各メンバーX) → 【お問い合わせ】saihate@someru.me → 末尾に `#最果てのハイライト #敗北者 #idol #ライブ #Shorts`。
- **タイトルテンプレ**: `2026/05/30 "曲名" 東名阪リリースツアー #最果てのハイライト #アイドル #idol`。

関連: [[project_saihate_brand_info]]
