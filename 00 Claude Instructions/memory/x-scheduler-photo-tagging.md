---
name: x-scheduler-photo-tagging
description: X/IG予約投稿の写真アカウントタグ事情。X APIは非対応・IGは自社のみ審査不要でuser_tags可・Publerが唯一の既製解
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2b5658c0-ac51-441d-ba33-716a38de61c7
---

X(Twitter)/Instagram の「予約投稿 × 写真へのアカウントタグ付け」可否の調査結果(2026-06)。[[project-x-scheduler]] の前提。

## X(Twitter)
- **写真へのアカウントタグ(Who's in this photo)は X API 非対応**。作成・読取どちらも不可、提供予定なし(開発者フォーラム明言)。純正アプリ/Web限定。
- → 自作ツール(公開API)では原理的に不可。本文@メンションは別物。**リプに @アカウントを載せる方式で代替**。
- リプ予約は v2 `POST /2/tweets` の `in_reply_to_tweet_id` で可能。
- 料金: 2026/2〜従量課金デフォルト。**1投稿 $0.01**、読取 $0.005。無料枠 月1,500write。旧Basic($200)/Pro($5,000)新規停止。

## Instagram
- 写真への `user_tags`(座標タグ)**対応** ＝ X でできない写真タグが IG なら可能。
- 最初のコメントを API 自動投稿可(`POST /{media-id}/comments`)= X のリプ相当。
- **自社アカウントのみなら Meta アプリ審査・ビジネス認証は原則不要(Standard Access)**。アプリのビジネス/ロールに対象アカウントを紐付けるだけ。審査が要るのは他人のアカウントを扱う Advanced Access のみ。
- 条件: プロアカウント+FBページ連携、画像は公開URL必須、公開は media コンテナ作成→media_publish の2段。

## 既製ツール(写真タグ×予約)
- **Publer**: 唯一確実に対応(画像鉛筆→Tag people 最大10)。ただし UI 英語、課金はアカウント単位。
- SocialDog(日本語UI): 画像タグは予約と併用不可・リアルタイムのみ。
- Buffer: 本文@メンションのみ。Hootsuite: 未確認。
- 共通: タグ相手が「写真タグ許可」設定にしてないと付かない(最大10)。
