---
name: mi-mi-gas
description: mi-mi+ レンタルのLINE/予約/決済を動かす本番Apps Scriptプロジェクトの正体・scriptId・構成・ローカルバックアップ場所。LINE着信処理の実装方針。
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e1f01e7-68b7-4ecd-b31f-2d2d123b1e78
---

mi-mi+ レンタルの**本番バックエンドは1個のGAS Webアプリ**。ブリーフでは「定型連絡botをこれから構築」とあったが、実際は2026-06-09時点で**ほぼ全部すでに本番稼働中**だった（[[project_mimi_line_auto_response]] の「並行bot構築」は実質完了済み）。

## 本番プロジェクト
- GAS名: **rental-availability-form** / scriptId `1W7qkhkzW_74f7kDNnOu0sKXHes2qEr0JSf6minQjzX0GuiRcXB8t37Uv`
- 所有: **yuki.watabe@someru.me**（clasp は2026-06-10にこのアカウントで再認証。トークンは期限切れに注意、切れたら `clasp login`）
- ローカル+git: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/rental-availability-form/`（.clasp.json 設定済。2026-06-10に初めてlive pull+gitバックアップ。それ以前は**GASエディタ内のみでバックアップ無し**だった）
  - `コード.js`(131KB) = 本体ルーター / `StripeConsent.js`(65KB) = 同意書・Stripe・振込・領収書・請求額計算 / `index.html` / `appsscript.json`
  - ※ `rental-form-vercel/StripeConsent.gs.txt` は古い手動部分バックアップ。真実はlive。

## doPost ルーティング (コード.js:919)
1. `?webhook=stripe` → `handleStripeWebhook_`（カード入金検知）
2. `body.action` あり → `handleApiAction_`（Vercelフロントからの予約フォームJSON API: getGarments/checkAvailability/submitMultiBooking/getBookingForConsent/saveConsent 等）
3. LINEイベント → `handleLineMessage_`(テキスト) / `handleLinePostback_`(ボタン)

## LINE着信の自動処理（重要・現状の実装方針）
- **テキスト**（`handleLineMessage_` コード.js:973）: 自動処理は **「領収書」キーワードのみ** → `handleReceiptKeyword_`。それ以外の自由文は「直近30分の確認中/仮予約(LINE User ID空)」にUser ID+表示名を紐付けて承りPushするだけ。**汎用Claude FAQ応答は本番に無い**。一般質問は手動チャットへ（[[project_mimi_line_ai_response]] の方針と整合：自由文は人が対応）。
- **postback ボタン**（`handleLinePostback_` コード.js:1071）: `confirm:yes:<pid>`→同意書URL送付 / `confirm:no`→フォーム再送 / `paid`→入金通知 / `confirm_paid/unpaid`→入金確定 / `change_addr/change_time`→変更受付 / `returned`→返送報告 / `report:agreement|payment`→完了報告。各操作はSlack通知も飛ぶ。
- 定期トリガー: 開始/終了通知・自動キャンセル(複数)・振込確認・出荷リマインド・ペア同意伝播 等が `コード.js`/`StripeConsent.js` に多数。

## FAQ bot との関係
- `mimi-plus-line-bot`（scriptId `1J_by...`, **admin@someru.me 所有**, Claude+knowledge.gs のFAQ応答bot）は**本番webhookに繋がっていない＝休眠**。1チャネル=Webhook1本で、本番は上の /exec。
- つまり「ブリーフ6定型対応(領収書/同意書URL/Notion入力/予約確定/支払い案内/内容修正)」は全部live済。**唯一の未実装ギャップ=自由文をClaudeで意図解析して返す層**。これを入れるかは顧客体験ポリシー判断（過去「適切な回答が見つかりません」誤爆で自由文自動応答を止めた経緯あり→慎重に）。

**How to apply:** 本番をいじる時は必ずこの rental-availability-form/ で `clasp pull`→編集→`clasp push`→既存デプロイのバージョン更新（/exec URL固定）。新規デプロイ作成はNG（webhook URL変わる）。本番 /exec = deploymentId `AKfycbxC7JXpttF6S9mIsQ8WhdkjxSYvOJ7XBW2k1ftip4KbcobcjBPC8yIsm3yyq0sElbSewg`（Vercel/LINE/Stripe共通）。**本番 clasp push/deploy はユーザーが手動実施**（Claudeは clasp pull・読み取りのみ可）。

## 衣装の自走変更 (2026-06-15実装・2026-06-17 本番デプロイ済み v106)
**本番反映完了**: change.html(Vercel)+GAS(コード.js/StripeConsent.js)ともデプロイ済み。GASはChrome経由で git diff のハンク単位base64注入(全文チェックサム照合)→ドライブ保存→デプロイ管理で既存デプロイ(AKfycbxC7JXpttF6…=本番/exec)をバージョン106に更新(URL不変)。実API検証: /exec 生存(getBookingForChange→トークン検証失敗JSON正常)、getGarments=40着全てprice有り(¥15000×25/¥16000×15=同額候補が実在)。残E2E: 実予約の有効トークンで garmentOptions が返るか(=実change linkで確認)。
### 詳細
既存の自走変更フォーム(change.html + getBookingForChange_/changeReservation)に「衣装変更」を加算追加。**同額・期間空き・単品予約のみ**自走許可(ユーザー決定)。コード.js: `garmentChangeOptions_`(予約1回取得で同額/空き候補を返す)・`validateGarmentSwap_`(サーバ再検証)・`bookingPlanDays_` 追加、getBookingForChange_に garmentOptions/currentGarment 返却、changeReservationに garmentId 分岐(レンタル衣装(決定)更新+予約情報要約の【衣装】同期)。StripeConsent.js: buildChangeRequestFlex_ 文言更新。**同額判定=garment.price(衣装マスタ「値段」)の厳密一致**(プラン追加料/送料/オプション不変→請求総額・同意書も不変)。完全に加算的(garmentId無しは従来挙動)。**change.htmlはVercelデプロイ済(前方互換でGAS未デプロイ時はセクション非表示)。GAS本番(コード.js/StripeConsent.js)は手動デプロイ待ち**(ローカルcommit 90ff5a0)。変更リンクは入金完了後に自動送信(sendChangeRequestButtonsAfterPayment_)。

## LINE User ID 取り違えバグ 根治 (2026-06-19・本番v148)
**症状**: お客様Aが別のお客様Bの予約情報をLINEで受け取る(誤送信)。山内様=宮前美来様の予約に山内様IDが居座り→宮前様の自動連絡が山内様へ。
**根本原因**: `handleLineMessage_`(コード.js)→`findRecentEmptyReservation_` が、メッセージ送信者のUser IDを「直近30分の確認中/仮予約(LINE User ID空)」へ**本人確認なしで紐付ける**。送信者が別件で来た既存客でも、たまたま直近にあった他人の新規予約に紐付く。フォーム送信時はUser ID空(`【DEBUG】lineUserId=(empty)`)で必ずこの後付け経路を通る。
**恒久対策(本番v148・Chrome経由デプロイ・deploymentId AKfycbxC7JXpttF6…=URL不変)**: handleLineMessage_ に取り違え防止ガード2点を追加(フェイルセーフ=迷ったら紐付けず routeFreeTextMessage_ へ)。
 1. `userIdAlreadyLinked_(userId)` — そのUser IDが既にいずれかの予約に紐付いてたら新規予約へ再紐付けしない(山内様ケース直撃)。
 2. `countRecentEmptyReservations_() > 1` — 直近30分の未紐付け仮予約が複数なら本人特定不能→自動紐付け停止。
 注入は live monaco モデルへ文字列置換(アンカー一意性+構文new Functionパース+マーカー数で検証してから setValue)→Cmd+S保存→デプロイ管理で既存デプロイをv148に更新。/exec getGarments=200/40着でコンパイル健全確認。
**データ修復済**: 宮前美来様(383f0338-a7bf-8125…)の LINE User ID + 表示名 を空にクリア済(誤紐付け除去)。山内様ID U00a59…は現在 山内文乃様の予約1件のみ=正常。
**ゆづき様(=秋山結月様, 382f0338-a7bf-81a7…)**: 表示名ゆづき/ID Uc6b38043… は秋山結月様の予約1件にしか存在せず、メール yuzufinity@icloud.com とも整合=本人予約。**現存する取り違えは無し**(山内様型ではない)。過去の誤送信があったとしてもデータ痕跡なし+根本対策で再発しない。秋山結月様のIDを消すと本人連絡が切れるので確証なき修正はしない方針。
**⚠️ ローカルドリフト**: ローカル `コード.js`(commit 90ff5a0≒v106)は他セッションの v107-148(receipt-issuer-address修正・本ガード等)を含まず**本番より古い**。clasp認証切れ(invalid_rapt)でpull不可。**本番=live GASが唯一の真実**。ローカルからの再デプロイは厳禁(回帰する)。要 GAS v148 から再同期。

## 決済リンク再発行 reissueCheckout (2026-06-23・本番@175)
Stripe Checkout Session は**作成から24hで失効(延長不可)**。同意書完了後に時間が経つとカード決済リンクが死ぬ。再案内用に doPost アクション `reissueCheckout` を追加(コード.js handleApiAction_ ルーター + StripeConsent.js `reissueCheckout_`)。
- 動作: `{action:'reissueCheckout', payload:{pageId}}` → getBookingForConsent_ で予約取得 → createStripeCheckoutSession_ で新セッション発行 → Notion 決済リンク/決済ID/決済ステータス(送付済) を更新 → `{ok,url,sessionId,amount,breakdown}` 返却。**LINE送信はしない(URLを返すだけ)**。
- webhook は `session.metadata.pageId` で予約特定するため、再発行リンクでも決済→自動確定(入金日時・領収書)が成立。
- **呼び出しの罠**: GAS /exec を `curl` で叩くとリダイレクト先でDrive「ページが見つかりません」になる(getFormConfig等の既存アクションも同様)。**本番フロントと同じ allowed origin(例 rental-form-vercel.vercel.app) のページを開いて `fetch` で叩くと成功**。Chrome MCP javascript_tool で実行可。
- 稲見一平様(pageId 37cf0338a7bf81d9a7ade8044bea4a6b)で実行→新リンク発行→LINE送信まで完了(2026-06-23)。

## clasp 再認証＆安全デプロイ手順 (2026-06-23 実証)
- **clasp 再認証済**: 2026-06-23 `clasp login`(yuki.watabe@) でトークン回復、pull/push/deploy 全部復活(旧メモの「invalid_raptでpull不可」は解消)。`clasp login` はバックグラウンド実行→ブラウザOAuthをユーザーが承認→localhostコールバックで完了。
- **回帰を避ける安全手順(ローカルが古いため必須)**: ①一時dir(/tmp)に .clasp.json コピーして `clasp pull`(=本番HEAD取得) ②pullした本番ファイルに編集を当てる ③一時dirから `clasp push -f` ④`clasp deploy -i AKfycbxC7JXpttF6S9mIsQ8WhdkjxSYvOJ7XBW2k1ftip4KbcobcjBPC8yIsm3yyq0sElbSewg -d "..."`(既存デプロイを新版に=URL不変)。**ローカルのリポジトリから直接 push 厳禁**(v107以降の本番機能を全消しする)。
- デプロイ一覧: HEAD用 `AKfycbzQ…`、本番(Vercel/LINE/Stripe共通) `AKfycbxC7JX…`。今回 @174→@175。
- **方針更新**: 旧「clasp push/deployはユーザー手動のみ・Claudeは読み取りのみ」は、ユーザーが明示的にフル対応を指示した場合は上記安全手順でClaudeが実行してよい(2026-06-23 稲見様対応で渡部承認のもと実施)。
- **未解決**: ローカルgit(HEAD 90ff5a0)は本番@175(v107-175の全機能: renderConsentPage_/getPublicBookingFormUrl_/LINE紐付け要約/取り違えガード/衣装変更/reissueCheckout等)より古いまま。**ローカルgitを本番から再同期してcommitする作業が要**(別タスク)。

## 自由文AI層 (2026-06-10 デプロイ済・既定OFF)
本番に `FreeTextAI.js` + `Knowledge.js` 追加済（deploy @87、`FREETEXT_AI_MODE` 既定off）。`handleLineMessage_` の自由文フォールスルーから `routeFreeTextMessage_` を呼ぶ。`draft`=Slackに返信案(顧客自動送信なし) / `hybrid`=安全intent(領収書/振込報告/返送報告/住所・時間変更/予約導線)のみ自動実行、一般質問・キャンセルは常にdraft。**残タスク**: ① Script Property `ANTHROPIC_API_KEY` 設定（本番未設定。請求書botと同じAnthropic鍵）② エディタで `testFreeTextClassify` ドライラン ③ `FREETEXT_AI_MODE=draft` で開始→数日観察→`hybrid`。

### ⚠️ 誤爆バグと修正 (2026-06-23・本番@176)
**症状**: `FREETEXT_AI_MODE=off`なのに、既存予約客の自由文に**新規予約の日程案内**や**支払い相談holding**が自動返信されて会話が噛み合わない(稲見様・山内様で発生)。
**原因**: `routeFreeTextMessage_` 内で `_buildRentalScheduleAutoReply_`(日程案内, `FREETEXT_SCHEDULE_AUTO_REPLY`既定'on') と `_buildPaymentConsultAutoReply_`(支払いholding, **キルスイッチ無し**) が、modeガード(`if(mode!=='draft'&&mode!=='hybrid')return`)より**手前**で実行されていて、modeに関係なく常時発火していた。両者とも「送信者が既存予約客か」を見ずパターン一致だけで返信。
**修正(@176)**: `var aiModeOn=(mode==='draft'||mode==='hybrid')` を追加し、両自動返信を `aiModeOn` 連動に(`scheduleReply=(!aiModeOn||scheduleAutoMode==='off')?null:...` / `paymentConsultReply=!aiModeOn?null:...`)。**off(既定)中は両方発火しない=自由文は人対応(Slack下書き)へ**。新規問い合わせ向け自動返信を復活させたい時は mode=draft/hybrid に。
**補足**: userIdで既存客を弾くガードは[[project_mimi_line_auto_response]]のフォームUserID≠実チャットUserID食い違いで取りこぼすため不採用。確実なのは自動返信自体をoff。
