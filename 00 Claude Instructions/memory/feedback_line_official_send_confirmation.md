---
name: feedback-line-official-send-confirmation
description: LINE公式アカウント（mi-mi+ 等）で相手に文章を送る前は、必ず文面をユーザーにチェックさせてから送信する
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c55fd1cd-4a2d-4942-8462-f525fc4f6b28
---

LINE公式アカウントから顧客／取引先に文章を送る際は、送信ボタンを押す前に必ず文面（宛名・本文・添付URL等すべて）をユーザーに提示し、承認を得てから送信する。

**Why:** 公式アカウントの発信は店舗の信用に直結するため、トーン・敬称・誤字・添付内容を本人が最終確認したい。

**How to apply:**
- LINE Official Account Manager (manager.line.biz / chat.line.biz) で送信操作をする場合に常に適用。
- 「文面そのまま使って」と明示的に言われた場合でも、URLや絵文字の追加等で内容が変わったタイミングで再確認。
- 入力欄に文面を入れるところまでは進めてよい。送信ボタンの押下だけ承認待ち。
- **例外 (2026-06-09〜)**: mi-mi+ レンタルの定型連絡（同意書URL送付・契約者情報入力・領収書・予約確定・支払い案内・内容修正の箇所確認）は、ユーザー指示により Claude 自走で**事前承認を省略**してよい。ただし**送信直前に URL 照合（location.href の宛先 User ID 一致確認）を必ず実施**して誤爆を防ぐ。金額変更・返金・キャンセル・トーン判断が難しい個別案件は従来通り承認を取る。詳細は [[project_mimi_line_auto_response]]
- 関連: [[reference-mimi-contract-template]] [[feedback-mimi-invoice-format]] [[project_mimi_line_auto_response]]
