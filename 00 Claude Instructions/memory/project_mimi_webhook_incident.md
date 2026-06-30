---
name: mi-mi-line-webhook-2026-06-11
description: mi-mi+公式LINEのWebhook URLが休眠FAQ botに差し替わりお客様メッセージが無反応になった障害と修復。再発時のチェックポイント。
metadata: 
  node_type: memory
  type: project
  originSessionId: 86231a4a-6a08-4ca0-90c4-a7817ab3a115
---

2026-06-11 発覚・修復。

## 症状
お客様のLINEメッセージが全て無反応（領収書キーワード自動送信・予約フォーム紐付け・自動応答が動かない）。GAS実行ログにLINEテキストの doPost が無い（Stripe webhookの doPost はあった）。

## 原因
LINE Official Account Manager の Messaging API > Webhook URL が、**本番GAS（rental-availability-form @87, `AKfycbxC7JX…/exec`）ではなく休眠FAQ bot（mimi-plus-line-bot, `AKfycby3YYBd…/exec`、GETすると「mi-mi+ LINE bot is running.」）に差し替わっていた**。誰かが設定を触った形跡。同時期に**応答時間設定もOFF**になっていた。

## 修復
1. manager.line.biz `@704ypmmu` > 設定 > Messaging API で Webhook URL を本番 /exec に書き戻して保存（React制御フォームのため execCommand('insertText') で入力→保存ボタン）。リロード検証済み。
2. 応答設定 > 応答時間を ON に復元（火-土11-21、時間内=手動チャット、時間外=応答メッセージ）。[[mimi-line-ai-response]] の設計に戻した。

## 教訓・チェックポイント（再発時）
- LINEが無反応 → まず Messaging API の Webhook URL が本番 /exec (`AKfycbxC7JX…`) か確認。
- **Push API 400「Failed to send messages」はトークン無効(401)ではなく宛先User ID無効の典型**。`testPushLine` のUser IDは「chatURL推定」の架空値なので400が出るが Push自体は正常。実在お客様には届く。
- 復旧確認: お客様の「領収書ください」で自動領収書が届くか（2026-06-11 Harunaさんで成功確認）。

## 関連
[[mi-mi-gas]] [[mimi-line-ai-response]] [[project_mimi_line_auto_response]]
