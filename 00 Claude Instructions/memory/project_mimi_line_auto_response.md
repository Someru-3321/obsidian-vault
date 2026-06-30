---
name: mi-mi+ LINE定型連絡 Claude自走対応
description: mi-mi+レンタルのLINE公式定型連絡をClaudeが自走対応する方針＋LINE Chat web版への送信技術＋誤爆防止
metadata:
  node_type: memory
  type: project
  originSessionId: 371d88b6-6ed4-4be4-936d-8857d8be5685
---

2026-06-09 ユーザー指示「今後この類の連絡は自動で対応してほしい」→ **両方併用**を選択。

> **2026-06-10 追記（重要・実態修正）**: 下記「並行bot構築（別タスクで構築予定）」は実は**ほぼ完了して本番稼働中**だった。本番=GASプロジェクト rental-availability-form ([[project_mimi_rental_backend]])。領収書/同意書URL/Notion入力(saveConsent)/予約確定/支払い案内/内容修正(confirm:no) は全部 postback・キーワードで自動化済。**唯一の未実装は自由文をClaudeで意図解析する層**。「並行botを一から作る」ではなく rental-availability-form を拡張するのが正しい。

## 方針：両方併用
- **当面**: Claudeが自走でLINE定型連絡を処理
- **並行**: ~~Apps Script + Claude API のLINE自動応答bot構築（別タスクで構築予定）~~ → 実態は構築済(上記追記)。残りは自由文Claude応答層のみ。

## Claude自走の対象（定型連絡）
内容修正依頼の箇所確認 / 同意書URL送付 / 契約者情報のNotion入力 / 領収書発行 / 予約確定連絡 / 支払い案内（請求額計算→Stripe/振込案内）

## 承認ルール（重要・[[feedback_line_official_send_confirmation]] の例外）
- 上記**定型連絡はLINE送信の事前承認を省略してよい**（ユーザー2026-06-09指示）
- **ただし送信直前にURL照合を必ず実施**（誤爆防止）。`location.href` の宛先User IDが対象と一致するか確認 → 不一致なら ABORT
- **重い判断は従来通り都度確認**: 金額変更・返金・キャンセル・新規ルール作成・破壊的操作・トーン判断が難しい個別案件

## LINE Chat web版 送信技術（chat.line.biz）
入力欄は `textarea-ex` カスタム要素（Shadow DOM）。通常のDOM操作・`insertValue()` は効かないことがある。
- **入力**: `const ta = document.querySelector('textarea-ex').shadowRoot.querySelector('textarea.input')` に native value setter で値セット → `ta.dispatchEvent(new InputEvent('input',{bubbles:true,composed:true,inputType:'insertText'}))`。これで内部 `___rawValue` に反映される。
- **送信**: textarea-ex と shadow textarea 両方に `new KeyboardEvent('keydown',{key:'Enter',keyCode:13,bubbles:true,cancelable:true,composed:true})` を dispatch。
- **クリア**: native setter で空文字 → 同じ InputEvent。
- **⚠️誤爆注意**: LINE Web版は裏で表示チャットを勝手に切り替えることがある。挿入・送信の直前に必ず `location.href` のUser IDを照合（不一致ならABORTするガードを入れる）。下書きはlocalStorage非永続だが切り替わった先のチャットに残るので、誤チャットを開いてクリアする。2026-06-09 心優さん宛で誤爆ニアミス（竹口光莉宛文面が別チャット下書きに混入）→ URL照合ガードで阻止。

## フォームUser IDと実チャットUser IDの不一致（重要）
予約フォーム(rental-availability-form/LIFF)送信時にNotion「LINE User ID」へ記録される値と、LINE公式チャットで実際にやり取りしているUser IDが**別アカウントのことがある**。例: 梨華ち様 Notion=`U383c123e14282a84df3ce807d6d8ca38` / 実チャット=`Uef19e268c2afcdade9edc870fa229301`（竹下陽乃でも同様パターン）。
→ Notion記録のUser IDで直接 chat URL を開くと別チャットや404になることがある。**LINE表示名で検索して開き、会話内容で本人確認**してから送る。送信ガードは「今表示中のチャットURL」で行う。実チャットUser IDは Notion 備考に記録しておくと次回スムーズ。

## 複数Chrome接続時
LINE操作は仕事用 Mac Book Air (yuki.watabe@someru.me) で。複数Chrome接続時は select_browser で deviceId 指定。ブラウザ切替後はアカウントが「ミミメイド(管理用)」になっていることがあるので mi-mi+ に切り替える。

## 関連リソース
- 同意書URL: `https://rental-form-vercel.vercel.app/consent.html?pid={Notionページid(ダッシュ付き)}`
- 出入管理表【mi-mi +】: collection://65072907-b89f-41a9-98d7-4aeeacfe0322
- [[project_mimi_line_ai_response]] / [[project_mimi_brand_tone_guide]] / [[project_rental_availability_form]]
