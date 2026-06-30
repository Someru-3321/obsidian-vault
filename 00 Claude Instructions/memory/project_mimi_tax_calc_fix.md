---
name: mi-mi
description: mi-mi+レンタルのStripe/LINEフォーム請求額が消費税を取りこぼしていたバグの修正内容とデプロイ手順。2026-06-11時点デプロイ未完了の引き継ぎ。
metadata: 
  node_type: memory
  type: project
  originSessionId: 86231a4a-6a08-4ca0-90c4-a7817ab3a115
---

2026-06-11 発見・修正（**ローカルのみ。本番デプロイ未完了**）。

## バグ
`rental-availability-form/StripeConsent.js` の `calculateBreakdown_` が、表記値段（衣装¥15,000・送料等）の合計を「税込」とみなし `taxAmount = total*10/110` で内税逆算していた。さらに Stripe line_items の unit_amount も税抜額そのままで課金 → **消費税分を取りこぼして安く請求**していた。
- 例: 齊藤さん 衣装15,000+京都送料1,300 → 旧¥16,300（税込扱い）。正しくは外税で **¥17,930**(=16,300×1.1)。

## 発覚の経緯
振込客はMF請求書（外税で正しい。例: 齊藤さんMF請求書 2026-05_925-1 = ¥17,820）、クレカ客はLINEフォーム（税込扱いバグ ¥16,300）で金額が食い違っていた。齊藤さんが「友人と比べ振込が安い」と気づき発覚。**MFが正・LINEフォームがバグ**。※MFの送料が¥1,200で作られていたケースあり（京都府は正しくは¥1,300＝YAMATO_SHIPPING_FEES通り。MFの¥1,200が誤り）。

## 修正内容（ローカル StripeConsent.js、git diff確認済・**未push**）
1. `calculateBreakdown_`: netExclTax=税抜合計、taxAmount=Math.round(netExclTax*0.1)外税、total=netExclTax+taxAmount(税込)
2. `getOrCreateStripeTaxRate_` 追加（消費税10% inclusive=false の tax_rate を作成し Script Property `STRIPE_TAX_RATE_ID` にキャッシュ）
3. Stripe line_items 各明細に `tax_rates[0]` 付与（税抜単価のまま外税加算、レシートに消費税明記＝インボイス対応）
4. `buildBreakdownTextLines_`: 「小計(税抜)/消費税(10%)/合計(税込)」表示に
5. 支払案内の注記を「※上記の合計は消費税(10%)込みの金額です」に

## 残タスク（**本番push/deployはユーザー手動**＝[[mi-mi-gas]] のルール）
- `clasp login` 再認証（rapt切れ invalid_grant）→ `clasp push` → GASエディタで既存デプロイ**@87のバージョン更新**（新規デプロイNG=webhook URL変わる）
- 検証: `testTwoSetDiscount` 実行でtotalが税込か / **1件テスト決済で tax_rate と coupon(2着割引10%) の併用順序を確認**（ここだけ実挙動未検証）
- 方針: 既入金客（濱・陽葵・本吉・阿部ら¥16,300等）は**据え置き**、未入金から新価格

## 関連
[[mi-mi-gas]] [[project_mimi_line_auto_response]] [[someru_inc_invoice_number]]
