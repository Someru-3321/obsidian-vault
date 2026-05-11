---
name: TicketDive 主催者管理画面
description: TicketDive (チケット販売プラットフォーム) の主催者用管理画面のURL・運用メモ。染める株式会社のentertainmentアカウントで利用。
type: reference
originSessionId: 076ec7c9-4e40-41b5-b9a3-9d1f22112c3b
---
# TicketDive 主催者管理画面

## URL
- **主催者管理画面**: https://admin.ticketdive.com/event
- **新規イベント作成**: https://admin.ticketdive.com/event/new/1 (3ステップフロー)
- **新規アカウント開設フォーム**: https://ticketdive-prod-admin-form.web.app
- **公開イベントURL形式**: https://t-dv.com/{slug} または https://ticketdive.com/event/{slug}
- **LP**: https://lp.ticketdive.com

## ログインアカウント
- entertainment@someru.me (Chromeのbrowser deviceId: d49075eb-124e-450c-8e47-2fdcee80c6e2)

## イベント登録フロー (3ステップ)
1. **Step 1: イベントページの設定** - タイトル/詳細/URL slug/問い合わせ先/公演情報(日程・時刻・会場・出演アーティスト)
2. **Step 2: チケットの設定** - 販売スケジュール(先着/抽選, 公開日時, 販売期間, コンビニ払い等) + 販売券種(チケットタイトル/価格/枚数/購入制限/詳細/整理番号接頭辞)
3. **Step 3: イベント公開確認** - 内容確認 + 公開タイミング選択(今すぐ/予約/下書き保存)

## 出演アーティストの注意点
- 既存DBに登録されているアーティストは候補ドロップダウンから選択。完全一致しないと候補に出ない
- 大文字小文字の違いがあると「Otto」と入力しても既存「otto」候補が出て、Enterで小文字側が選ばれる
- 表記を変えたい場合はTicketDive運営に問い合わせが必要 (主催者管理画面からは編集不可)
- 「○○/○○/○○」と/区切りで複数アーティストをまとめて入力可能

## URL slug の制約
- 半角英数字とハイフン・アンダーバーのみ
- 数字のみは不可
- 6文字以上
