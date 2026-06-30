---
name: rental-availability-form
description: mi-mi+ レンタル空き確認+仮予約フォーム (Apps Script Web App)。お客様自身が空き判定+申込できる
metadata: 
  node_type: memory
  type: project
  originSessionId: a3d5b915-57a0-4a33-b8a1-b8ebca84915b
---

mi-mi+ 衣装レンタルの空き確認+仮予約申込を、お客様セルフサービスで完結させるためのフォーム。**カレンダー型UI**でお客様が衣装を選ぶと今後2ヶ月 (60日)の空き状況が一覧で見られる。

**Why:** 従来はお客様がLINE公式で問い合わせ → 我々がNotionを目視で空き判定 → 返信、という手作業フロー。お客様が「いつでも自分のタイミングで」各衣装の空き状況を確認できるようにすることで、我々の確認作業を削減 + お客様の待ち時間も短縮。

**How to apply:**
- ディレクトリ: `~/Library/CloudStorage/.../マイドライブ/Claude プロジェクト/rental-availability-form/`
- 構成: Apps Script Web App。`Code.gs` + `index.html` + `appsscript.json` + `SETUP.md`
- Notion接続: `NOTION_TOKEN` は rental-deadline-watcher と同じインテグレーショントークンを流用
- 出入管理表【mi-mi +】data_source: `65072907-b89f-41a9-98d7-4aeeacfe0322`
- 衣装一覧 data_source: `e27e3068-567b-4f82-a033-a9e5ec92524e` 【管理用】(在庫数プロパティで複数在庫の衣装にも対応)
- 公開用衣装DB: `22ff0338-a7bf-804e-8819-000bf1072248` 【公開用】(`モデル着用画像` / `衣装画像` ファイルプロパティから名前マッチで画像取得)
- 空き判定ロジックは [[project_mimi_rental_buffer]] のルール準拠。バッファ非対称: **前1日・後2日**。既存予約占有期間 `[b.start - 1, b.end + 2]` と お客様の使用期間 `[d, d + planDays]` が重なる日を埋まり扱い (在庫数 > 1 なら占有数 < 在庫数 で空き)
- ステータスフィルタ: `EXCLUDED_STATUSES = ['キャンセル', '利用なし', '記載メモ']` のみ除外。それ以外 (進行中・完了・利用停止・予約重複等) は全て予約済み扱い
- フロー: ①カラー選択→衣装(複数選択OK)→カレンダーで日付タップ ②連絡先入力 ③完了
- **個別カレンダーUI** (v5): 衣装カードに画像 + 名前 + シリーズ/カラー。タップで衣装下にインライン展開カレンダーが開いて、その衣装専用の空き日が見える。**衣装ごとに個別の日付選択** (= 1衣装1Notion エントリ)。複数衣装も別カラーもOK、しかも別の日付OK。サーバー側 `submitMultiBooking()` で `items: [{garmentId, startDate, plan}, ...]` を一括登録 → 各 item 1 Notion ページずつ作成 → Slack通知は1つにまとめ。
- **衣装画像** (v6-v7): 公開用DB (`22ff0338...`) の `モデル着用画像` / `衣装画像` ファイルプロパティを優先取得、無ければ管理用DBのページcover画像にフォールバック。名前マッチは `normalizeName_()` で正規化 (全角→半角カッコ・空白除去・もふもふ吸収・lowercase)。署名URLは~1hrでexpireする (キャッシュも5min)。
- 仮予約はステータス `確認中/仮予約` で登録 (rental-deadline-watcher のリマインド対象には乗らない)
- **LINE 連携強化** (2026-05-20 v3):
  - Notion DB に `LINE 表示名` 列追加 + 書き込み。タイトル `ご予約名` も `名前 様 (LINE: 表示名)` 形式に
  - 予約送信成功時に `liff.sendMessages()` で **お客様→公式LINE** に予約サマリを自動送信 (LINEチャット履歴に残り、誰の予約か視認可)
  - LIFFスコープに `chat_message.write` 追加
- 仮予約後の運用は [[project_mimi_booking_confirmation_template]] のテンプレでLINE返信 → 同意書・請求書発行 → `契約ご送付待ち`

主要API (`google.script.run` 経由):
- `getFormConfig()` マスタ + `liffId`(LIFF_ID プロパティ) + `lineUrl`
- `getGarments()` 衣装一覧 (5分キャッシュ、`clearGarmentCache` でリセット)
- `getAvailabilityCalendar({garmentId, fromDate, days, plan})` 指定衣装の日別空き
- `checkAvailability(...)` 単一日空き判定 (送信時の競合チェック用)
- `submitBooking(...)` Notion DB に「確認中/仮予約」で作成 + Slack通知

LIFF対応:
- スクリプトプロパティ `LIFF_ID` を設定 + LINE Developers Console で LIFFアプリ作成すると、LINE内ブラウザでフォームを開いた時に User ID + displayName を自動取得
- LIFF URL: `https://liff.line.me/{LIFF_ID}` → LINE公式リッチメニューに貼る
- 取得した LINE User ID は Notion DB の `LINE User ID` カラムに自動セット
- 外部ブラウザで開いた場合は LIFF ログインを強制せず通常Webとして動作

**【重要】2026-05-21 にアーキテクチャ変更**:

Apps Script Web App は sandbox iframe で動くため、LIFF SDK が parent frame と postMessage で通信できず init() が hang する構造的問題が判明。完全自動化のため、フロントエンドを **Vercel に別ホスティング**に移行。

**新アーキテクチャ**:
- **フロント**: Vercel 静的ホスティング `https://rental-form-vercel.vercel.app/` (GitHub `Someru-3321/rental-form-vercel`、main push で自動デプロイ)
- **API サーバー**: Apps Script Web App (v26+、CORS対応 JSON API)
- **LIFF エンドポイントURL**: `https://rental-form-vercel.vercel.app/` (LINE Developers Console で設定済み)
- **LIFFサイズ**: Full

**フロー (完全自動)**:
1. お客様がリッチメニュー「空き確認」 → LIFF URL → Vercel HTMLが iframe外で開く
2. LIFF SDK 正常動作 → User ID + 表示名 自動取得
3. フォーム送信 → Apps Script API (POST text/plain JSON) → Notion登録 + Push通知配信
4. お客様の手間ゼロ + 我々の手間ゼロ

**Apps Script Web App URL (API専用、v26+ デプロイ済み)**:
`https://script.google.com/macros/s/AKfycbxC7JXpttF6S9mIsQ8WhdkjxSYvOJ7XBW2k1ftip4KbcobcjBPC8yIsm3yyq0sElbSewg/exec`
※ API用 (doPost に action分岐 + handleApiAction_)。doGet?action=... もしくは doPost {action,payload} で getFormConfig/getGarments/getAvailabilityCalendar/checkAvailability/submitMultiBooking が呼べる

**旧 Apps Script HtmlService フォーム** (`script.google.com/.../exec` で HTML返却):
不要だが、互換性のため残してある (リダイレクトしてもOK)。LIFFは Vercel URL を見るので影響なし。

**今後の更新フロー**:
- フロント (HTML/JS) 修正 → `~/.../rental-form-vercel/` のindex.html 編集 → `git push origin main` で Vercel が自動デプロイ
- バックエンド (Code.gs) 修正 → Apps Script Editor で編集 → 保存 → デプロイ → デプロイ管理 → 編集 → **新バージョン選択** → デプロイ (新バージョン作らないと反映されない罠あり)

**LINE リッチメニュー (2026-05-21 大刷新)**:
5ボタン構成 / 高級ミニマルデザイン (cream背景 / 明朝 / 細罫線):
- ①左半分大: ご予約はこちら → LIFF URL
- ②右上左: レンタル一覧 → Notion公開DB
- ③右上右: お問い合わせ → postback `contact:inquiry` → 自動返信「内容を送って」
- ④右下左: 同意書・お支払い完了報告 → postback `report:menu` → Quick Reply 2分岐
- ⑤右下右: 利用規約 → Notion規定ページ

リッチメニュー画像生成: `/tmp/gen_richmenu.py` (Python PIL + ヒラギノ明朝)。GitHub repo `rental-form-vercel/richmenu.png` に置き、`https://rental-form-vercel.vercel.app/richmenu.png` 経由で Apps Script `setupRichMenu_()` から LINE Messaging APIにアップロード。再生成は `setupRichMenu` action を /exec に投げる: `https://script.google.com/macros/.../exec?action=setupRichMenu`。旧メニューは `deleteAllRichMenus` action で削除。

**LINE Push の確認ボタン (2026-05-21)**:
予約完了Pushに **Quick Reply + Flex Message ボタン** を併送。
- Quick Reply: items に「はい/修正したい」postback action
- Flex Message: footer に2ボタン (主ボタンpink #d0869f、副ボタンgray)
- 端末/バージョン差異対策で両方併送 → 確実に表示

postback処理 (handleLinePostback_):
- `confirm:yes:{pageId}` → Notion「注文確認【済】」=true + お礼返信
- `confirm:no:{pageId}` → 修正内容案内返信
- `report:menu` → Quick Reply「同意書/支払い」分岐
- `report:agreement` → 直近予約「同意 【済】」=true + ステータス「契約済 郵送待ち」進行
- `report:payment` → 直近予約「支払【済】」=true
- `contact:inquiry` → 自動返信「お問い合わせ内容を送って」

**通知文章フォーマット (2026-05-21 リファイン)** `buildBookingSummaryText_`:
mi-mi+ ブランド洗練デザイン。━━━ や ──── の区切り線、セクション見出し (ご予約者さま / ご連絡先 / ご予約内容 / お受取り / お届け先 / お支払い)。郵便番号・都道府県・住所・氏名・TEL・メールも全部含む。郵送時のみお届け先セクション表示。

**Step2 フォーム改修 (2026-05-21)**:
- LINE登録者 (readonly, LIFF displayName自動入力) と ご契約者氏名(本名) を分離
- 活動名/所属グループ 縦並びに変更 (placeholder見切れ対策)
- 活動ジャンル も必須化
- 使用用途 placeholder に「コンセプトカフェ出勤」追加
- 郵便番号 inputmode=numeric + 7桁数字バリデーション + Zipcloud API で住所自動入力 (`https://zipcloud.ibsnet.co.jp/api/search`)
- 利用規定リンク (Notion: `https://www.notion.so/someruinc/mi-mi-1e0f0338a7bf809ea52edb9346ed93ea`)

**スクリプトプロパティ追加** (2026-05-21):
- `LINE_CHANNEL_ACCESS_TOKEN` = mi-mi+ Messaging API (channel 2007740745) の長期トークン (Push送信 + リッチメニューAPI用)

**v12 (2026-05-20)**: 通常プランを 2泊3日 / 3泊4日 / 4泊5日 のみに削減 (ユーザー意向)。

**v13 (2026-05-20)**: 撮影プランとイベントプランを **1つに統合**。
- プラン名: `撮影&イベントプラン (撮影日1泊2日 + イベント日2泊3日)+7000円`
- このプラン選択時のみ、衣装カード展開時に **2つのカレンダー** を縦に並べて表示:
  - 撮影日 (1泊2日 で空き判定)
  - イベント日 (2泊3日 で空き判定)
- 両方の日付が選択必須 (validateBookingFormで部分入力エラー)
- 送信時に同じ衣装で `items` 2件展開:
  - 「【撮影日】衣装名」+ planDaysOverride=1
  - 「【イベント日】衣装名」+ planDaysOverride=2
- Notion登録は2レコード (撮影日用1泊2日 + イベント日用2泊3日)
- 料金 +7,000円 はセット
- BOOKINGS[i] 構造拡張: `shootDate / eventDate / shootCalendar / eventCalendar / shootViewMonth / eventViewMonth` (撮影&イベントプラン時のみ使用、通常プランは従来の `startDate / calendar / viewMonth` を使用)
- 新ヘルパー: `isShootEventPlan_(plan)` (識別) / `bookingHasDates_(b, plan)` (必要日付揃ってるか) / `buildCalSectionContainer_(kind, label)` (カレンダーセクション生成) / `loadCalendarSection_(booking, sectionElem, kind, planDaysOverride)` (kind指定でAPI呼出+保存) / `renderCalendarSection_(booking, sectionElem, kind)` (kind指定で描画)
- サーバー側 (Code.gs) `checkAvailability` / `getAvailabilityCalendar` / `submitMultiBooking` に **planDaysOverride** パラメータ追加。各items単位で日数指定可能に

**v13 プラン一覧 (計 4 つ):**
- 通常プラン【2泊3日】 (ベース)
- 通常プラン【3泊4日】+6000円
- 通常プラン【4泊5日】+12000円
- 撮影&イベントプラン (撮影日1泊2日 + イベント日2泊3日)+7000円

**v14 (2026-05-20)**: 2点改善。
- **Notionタイトル拡張**: `buildProperties_` で予約ページタイトルに**衣装名を含める** → 複数衣装予約時に区別しやすい。形式: `お名前 様 — 衣装名・衣装名 (LINE: 表示名)`
- **送料注記追加** (Step2 chkShipFee の下):
  - ※ 提携郵送会社(ヤマト運輸)で発送いたします。遅延等が発生した場合は弊社にて責任を負いかねます
  - ※ 返送代はお客様にてご負担をお願いいたします。着払いで返送された場合は受付できません

**v15 (2026-05-21)**: LINE自動送信が届かない問題のフォールバック。
- **Step3 完了画面にサマリ手動コピー追加**: LIFF.sendMessages 経由の自動送信が失敗した場合のフォールバック。
  - 完了画面に textarea (予約サマリのテキスト) + 「📋 サマリをコピー」ボタン
  - 注記: 「LINEに自動送信されなかった方へ - 下のテキストをコピーして mi-mi+ 公式LINEに送信してください」
  - クリップボードAPI (navigator.clipboard.writeText) + execCommand('copy') フォールバック
- 新関数: `fillSummaryCopy_(p)` (textareaにサマリ埋め込み) / `copySummary_()` (クリップボードコピー)
- onSubmitResult成功時に fillSummaryCopy_ 呼ぶ。

**LIFF Scope確認** (2026-05-21): `profile, chat_message.write` 両方とも有効に設定済み (LINE Developers Console)。LINE自動送信が動かない原因は別 (お客様の許可状態 / リッチメニュー設定 / SDK動作)。v15でフォールバック実装。

**v17 (2026-05-21)**: Notion予約ページから1クリックでLINEチャットに飛ぶ機能。
- `buildProperties_` のタイトル rich_text を拡張: メインテキスト + 「👉 LINEを開く」 リンク (青色)
- リンクURL: `https://chat.line.biz/{OA_ID}/chat/{lineUserId}` (OA_ID=`U0f0de025e03cdfa092e5f20fe0f77bcd` = mi-mi+ Official Account の chat.line.biz 内部ID)
- 効果: Notion 予約ページ開く → タイトルの「👉 LINEを開く」をクリック → 該当お客様の LINE チャット画面に直接ジャンプ → どのお客様かすぐ照合可能
- `lineUserId` が空の場合はリンク追加しない (通常通り)
- 定数 `LINE_OA_ID` を Code.gs に追加

**v18 (2026-05-21 01:42)**: **v17 重大バグ修正**。v17でNotionタイトルrich_textに `annotations: { color: 'blue' }` を入れたところ、Notion API が title プロパティに対する annotations.color を **拒否して 400 を返していた**。submitMultiBooking はその例外を throw するが、Apps Script Web App 経由の例外は実行ログでは「完了」と表示されてしまうため気付きにくかった。結果として:
- ユーザーが予約送信 → Notion登録されない (実行ログは「完了」)
- LINE Push も飛ばない (Notion fetch例外で throw → push送信にたどり着かない)
- **修正内容**: Code.gs L575 `titleRich.push(...)` から `annotations: { color: 'blue' }` を削除。リンク自体は残存。「👉 LINEを開く」は色なしのテキストリンクで表示。
- **教訓**: Notion API の title プロパティでは rich_text 内に annotations を入れると拒否される。色付きリンクが必要な場合は別プロパティ (rich_text型) を作るべき。
- **教訓2**: Apps Script Web App 経由で google.script.run から呼ぶ関数で throw した場合、Apps Script 実行ログでは「完了」表示される (例外は google.script.run の onFailure callback に転送されるが、実行履歴上は失敗扱いにならない)。

**Push送信デバッグ結果 (2026-05-21)**: `testPushLine`/`clearGarmentCache` 経由で直接 LINE Messaging API push を叩いた結果:
- Token 正しい (172 chars)
- **HTTP: 400 / Response: `{"message":"Failed to send messages"}`**
- ただし v18 修正前のテスト結果。User ID `U85fe54b40278063148553bb2d92b4510` は chat.line.biz URL から推定したもので、LIFF経由の実Notion登録Userとは異なる可能性あり (v18でNotion登録が直れば、実Notionに記録された LINE User ID で再テスト可能)
- LIFF と Messaging API は両方とも **同じプロバイダー「make」配下** にあるため User ID は共通のはず (LIFF channel `2010141049` / Messaging API channel `2007740745`)
- v17のNotionリンク機能は LINE Push 失敗時でも有効 (Notion 上の予約ページから人間が直接チャット開ける)

**v16 (2026-05-21)**: LIFF.sendMessages の代替として **Messaging API Push** 実装。
- Code.gs に `pushLineMessageToUser_(userId, text)` / `buildBookingSummaryText_(payload)` 追加
- `submitMultiBooking` の末尾で `payload.lineUserId` があれば LINE Messaging API push 送信
- LINE Messaging API: POST `https://api.line.me/v2/bot/message/push` (Bearer auth)
- mi-mi+ Bot → お客様のLINEに予約サマリが直接届く
- **スクリプトプロパティ追加**: `LINE_CHANNEL_ACCESS_TOKEN` = mi-mi+ Messaging APIチャネル (チャネルID `2007740745`) の長期アクセストークン
- 対応するMessaging APIチャネルが LINE Developers Console > make プロバイダー > mi-mi+ (Messaging API) に存在
- お客様が公式LINEを **友だち追加済み** であることが前提 (push API の仕様)

**v8 (2026-05-20)** [v10で撤去]: 予約サマリ後に同意確認 Flex Message を追加。→ LIFF.sendMessages のFlex内 message action は自分のbubbleでは発火しない仕様のため v10 でテキスト案内に切り替え。

**v9 (2026-05-20)**: 廃盤運用ルール追加。**管理用DBで在庫数=0の衣装は `getGarments()` でスキップ** (= フォームから消える)。過去レンタル履歴のリレーションは温存。命名規則: 廃盤衣装は名前を `[廃盤] xxx` にprefixして人間の管理画面側でも一目で識別可能に。**初回適用**: パープルチュール (`6dd09b59-d4db-4c38-b0bf-11299e39fd61`)。

**v10 (2026-05-20)**: 3つの拡張+1つの修正。
- **PLAN_DAYS 8プラン化**: 通常【2泊3日】/【3泊4日】(延長)/【4泊5日】(延長)/【5泊6日】+10000円/【6泊7日】(延長)/【7泊8日】(延長)/撮影&イベント【1泊2日】+7000円/撮影&イベント【2泊3日】+7000円
- **飲食利用チェックボックス**: Step2 (決済方法の下) にチェック。送信時にプラン名末尾に `+ 飲食利用` を付与してNotion登録
- **Flex Message撤去→テキスト案内**: LIFFで送るFlex内ボタンは自分bubbleで動かないため、テキスト1通だけ送信。末尾に「上記の日程・内容で問題なければ「はい」と、修正したい場合は「いいえ」とお返事ください」案内→お客様手動返信運用
- **planDaysFor_ 改修** (client): prefixマッチで「+10000円」「(延長)」「+ 飲食利用」suffix無視して日数判定

**v11 (2026-05-20)**: 料金体系明示+撮影/イベント固定化+コンカフェ強制。
- **PLAN_DAYS 料金表示**: 通常プラン延長は **1日¥6,000** 加算で料金プラン名に明示:
  - 通常プラン【2泊3日】 (ベース)
  - 通常プラン【3泊4日】+6000円 (1日延長)
  - 通常プラン【4泊5日】+12000円 (2日延長)
  - 通常プラン【5泊6日】+10000円 (既存パック)
  - 通常プラン【6泊7日】+16000円 (5泊6日 +1日)
  - 通常プラン【7泊8日】+22000円 (5泊6日 +2日)
- **撮影/イベント固定化**: 用途別に1泊2日 / 2泊3日を分離リネーム:
  - 撮影プラン【1泊2日】+7000円
  - イベントプラン【2泊3日】+7000円
- **飲食利用 ¥6,000**: ラベルを「飲食利用 (+¥6,000) を含む / ※コンセプトカフェ等での着用の場合は必須でチェックしてください」に変更
- **コンカフェ強制バリデーション**: `useCase` / `activityName` / `group` に「コンカフェ」「コンセプトカフェ」「こんかふぇ」のいずれかが含まれる場合、`chkFood` 未チェックなら送信エラー

LIFF URL: `https://liff.line.me/2010141049-WRoWfjTf` (LIFF ID: `2010141049-WRoWfjTf`)

LINE公式リッチメニュー (2026-05-20 公開):
- タイトル: `空き確認 + レンタル予約`
- レイアウト: 大カテゴリ 上下2分割 (1200×810)
- 表示期間: 2026/05/20 00:00 - 2030/12/31 23:59
- 上ボタン (A): リンク → LIFF URL / ラベル「空き確認」
- 下ボタン (B): リンク → `https://www.instagram.com/mi_mi_plus/` / ラベル「レンタルご予約」
- 旧メニュー「♡レンタルご予約はこちらから♡」は `下書き保存` で待機中に退避 (richmenu id 13738613) — 復帰可能

スクリプトプロパティ (全て本番値設定済み 2026-05-20):
- `LIFF_ID`: `2010141049-WRoWfjTf`
- `NOTION_TOKEN`: rental-deadline-watcher と同じインテグレーショントークン
- `SLACK_WEBHOOK_URL`: rental-deadline-watcher と同じチャンネル Webhook

✅ セットアップ完了 — LINE公式リッチメニュー「空き確認」タップで本フォームが開く状態。

**2026-05-21 カレンダー2タップ式 (通常プラン)**:
- 1タップ目 = ご利用開始日, 2タップ目 = ご返却日 → diffDays_ から自動でプラン (2泊3日/3泊4日/4泊5日) を判定して `$('plan')` を切替
- ヘルパー: `diffDays_(y1,y2)` / `getPlanForDays_(days)` / `isPeriodAllAvailable_(booking,start,end)` / `showCalendarMsg_(garmentId,msg)`
- BOOKINGS[i] に `endDate` 追加。通常プランは startDate+endDate 両方ないと `bookingHasDates_` false
- 撮影&イベントプランは従来通り 1タップ式 (shootDate / eventDate)
- CSS: `.cal-day.range` (期間中ハイライト, ピンクボーダー) / `.cal-day.start-only` (開始日だけ選択中のリング)
- ステータス表示: 「📅 ご利用開始日をタップ」→「📅 開始: X → ご返却日をタップ」→「✓ N泊M+1日 X 〜 Y」
- 範囲内に予約済みの日が含まれる場合は赤エラーで弾く + 範囲が2/3/4泊以外もエラー

**2026-05-22 LIFFとMessaging API Linked OA 設定** ([liff-apps-script-iframe-incompatibility]] と同様の連携問題):
- LINE Login Channel (2010141049) の「友だち追加オプション > リンクされたLINE公式アカウント」が **未設定だった**
- → LIFFが返す User ID と Messaging API Channel の User ID が**不一致** → submitMultiBooking の Push が常に失敗
- 設定: チャネル基本設定 → リンクされたLINE公式アカウント → `@704ypmmu/mi-mi +` を選択
- これで以降の新規お客様は LIFF→Messaging API 同一 User ID 取得 → Push 通知届く
- 既存お客様 (リンク前にLIFF経由のユーザー) は旧 User ID のままなので Push 失敗、手動LINE Manager対応必要

**2026-05-22 LINE Login Channel 公開化**:
- LINE Login Channel が「Developing」状態だったため、開発者以外のユーザーが LIFF アクセス時に 400 Bad Request "User need to have developer role"
- LINE Developers Console → チャネル状態を「Published」に切替 (この操作は不可逆)
- 全LINEユーザーが LIFF アクセス可能に

**2026-05-22 Code.gs v32 デプロイ**: タイトル整理 + LINEチャットURL独立 + Push失敗時Slack通知
- `buildProperties_`: タイトルを「お客様名 様」のみに簡素化 (撮影&イベント時は `(撮影日 M/D)` or `(イベント日 M/D)` 付与)
- Notion DB `LINEチャット` (URL型) プロパティを独立化 → タイトルからLINEチャット直リンクを除去
- `submitMultiBooking` の Push 失敗時に `notifyPushFailure_` 呼出 → Slack スタッフ通知 (人間が即気付けるフェイルセーフ)

**2026-05-22 Stripe + LIFF同意書 自動化システム (構築中)**:
- 同意書/お支払い 自動化フロー: 予約→お客様「はい」→ 同意書LIFF→Stripe Checkout (クレカ/コンビニ/PayPay) → Webhook自動消込 → Notion更新 → 領収書はLINE「領収書ください」キーワードで自動発行
- MF クラウド (請求書 + 契約) からの脱却、月¥5,500前後の固定費削減見込み
- Notion DB に8プロパティ追加: 同意書 提出日時/署名画像/提出IP、決済リンク/決済ID/決済ステータス/入金日時、請求金額、領収書宛名/領収書希望/領収書送付済、LINEチャット
- consent.html 作成 (rental-form-vercel): PDF同意書スクロール+チェック+サインpad
- payment_success.html 作成: Stripe Checkout 完了後リダイレクト先
- Apps Script Stripe統合コード `/tmp/apps_script_stripe_full_v1.gs` (440行) 準備済 — Stripe Test APIキー入手後に Code.gs に投入予定
- ScriptProperties 必須: STRIPE_SECRET_KEY / STRIPE_WEBHOOK_SECRET / CONSENT_FORM_URL / INVOICE_REGISTRATION_NUMBER (=T6011001142353)
- Stripe ダッシュボード設定: 支払い方法 (カード/Konbini/PayPay) 有効化、税ID T6011001142353 登録、Webhook URL=`<Web App URL>?webhook=stripe` で checkout.session.completed 監視
- お客様体験: 1つのCheckout URLからクレカ/コンビニ/PayPayを選択 → 完全自動消込 → Notion「支払済」 → Slack通知 → スタッフ発送のみ
- 領収書: Stripe自動メール OFF (希望者のみ)、LINE「領収書」キーワード → Stripe Receipt URL を自動LINE送信 + Notion「領収書送付済」更新
- Phase 2: PayPay 直接連動 (手数料3.6%→2.5%) 検討
