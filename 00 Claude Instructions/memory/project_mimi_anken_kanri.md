---
name: mimi-anken-kanri
description: mi-mi 衣装制作「案件管理システム」の本番化プロジェクト (Next.js+Supabase+Vercel)。旧Codex製アプリの土台入れ替え。
metadata: 
  node_type: memory
  type: project
  originSessionId: 46430e68-edf7-4356-899d-7adbf5492224
---

mi-mi 衣装制作の**案件管理システム**を、Notion完全脱却して「これ1つで運営」できる本番システムにするプロジェクト（2026-06-13開始）。レンタル側 [[project_mimi_admin]] とは別ドメイン（こちらは衣装"制作"案件：案件/工程DE初→DE完→TC→FG→納品→SNS/請求/勤怠/デザイン提出URL共有/役割権限）。

## 経緯・元の状態
ユーザーがCodex(OpenAI)で作った React+Vite 単一ファイルアプリ。`https://*.trycloudflare.com` の一時トンネルで公開してた。**致命的弱点3つ**: ①実データが `~/Documents/Codex/2026-06-13/.../project-state.json` という日付フォルダの単一JSONにしか無くgit無し(消失リスク) ②公開URLが一時トンネル(PC閉じると死ぬ) ③勤怠がlocalStorageのみ。→ ユーザー判断で **Next.js+Supabase+Vercel / 個人ログイン+役割 / 移行対象は衣装制作案件のみ** に決定。

## 置き場所・連携ルール(厳守)
`~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/mimi-anken-kanri/`。
**正本=GitHub Private `Someru-3321/mimi-anken-kanri`(origin/main)。Claude/Codex/2台PCで共有。AGENTS.md+STATUS.md準拠: 着手前に`git pull`+STATUS.md確認、完了後にSTATUS.md更新+commit+push。** ghは someru-3321 でログイン済。注意: _data-backups(顧客データPII)はgit/Vercel対象外(.gitignore/.vercelignore)だが過去コミットd976821の履歴には残存(privateなので可、消すなら履歴purge+force-push)。
- `web/` = 本番Next.jsアプリ（Vercelデプロイ対象） / `supabase/migrations/`(0001-0003)+`seed/migrate.mjs` / `_data-backups/`(旧データ保全) / `_legacy-codex-app/`(旧Codex版,参照のみ)。
- 手順の正本は `mimi-anken-kanri/SETUP.md`。

## Phase 1 完了済 (2026-06-13)
スキーマ設計・冪等移行スクリプト・旧UI(8タブ4557行)のNext.js移植・DB↔UI形状アダプタ(`web/lib/adapters.ts`)・APIルート4本(projects-state GET/POST, design-shares, staff-auth, notion-backup)。`next build` 通過・dev起動スモーク済。**設計判断**: service_roleはサーバAPIのみ/anonはブラウザ。profiles(スタッフ名簿)はauth.usersと分離(emailで後紐付け)。旧固定ID(u-admin等)↔DB uuidはアダプタが吸収(uuidv5決定的生成、migrate.mjsと同ロジック)。画像は当面メタのみ(Phase2でStorage化、旧dataURL埋め込み廃止)。

## Phase 1.5 完了 (2026-06-13) ＝本番稼働開始
**本番URL: https://mimi-anken-kanri.vercel.app** (Vercel someru-3321s-projects/mimi-anken-kanri, SSO保護なし=公開, アプリのパスコード mimi2026 のみがゲート)。
- Supabase: org「Someru」(GitHub someru-3321でログイン), project **mimi-anken-kanri** ref `djzpqiquhoahrzrspsdw` 東京リージョン。URL `https://djzpqiquhoahrzrspsdw.supabase.co`。新形式キー(sb_publishable_=anon相当/sb_secret_=service_role相当)を使用。DBパスワードはアプリ未使用(必要時Settings→Databaseでリセット)。
- スキーマ3本をSQL Editorで実行済。実データ移行済(profiles5/clients38/projects24/milestones144/memos24)。GET/POST往復をローカル+本番で検証済。
- Vercel env5本(SUPABASE_URL/SERVICE_ROLE_KEY/NEXT_PUBLIC_*/STAFF_ACCESS_CODE)Production設定済。`cd web && npx vercel --prod --yes`で再デプロイ可(CLIは someru-3321 でログイン済)。移行スクリプトは `supabase/seed/node_modules`→`../../web/node_modules` のsymlinkでESM解決。

## 残り
- **重要・ユーザー周知事項**: 旧Codexアプリ(ローカル:5173+trycloudflareトンネル)はまだ生きてる。移行スナップショット(2026-06-13 14:10)以降に旧アプリで入れた変更はSupabaseに無い。**今後は新URLだけ使う**ことの周知と、旧トンネル/旧プロセスの停止が必要。
- サブドメイン kanri.someru.me 化(VercelにDomain追加→someru.meのDNSにCNAME。DNS管理元の確認が要る)。
- **Phase 2 完了(2026-06-13)**: 勤怠をDB保存(/api/attendance GET/POST entry・punchIn/PATCH clockOut,二重出勤409)・請求をDB保存(/api/invoices GET/POST)・操作ログ(lib/audit.ts→audit_log)・同時編集対策(autosaveは変更案件のみ差分送信=lastSavedRefで前回保存と比較、他人の別案件を上書きしない)。本番検証+デプロイ済。
- **Phase 4 完了(2026-06-13)**: 案件新規作成(案件タブ「新規案件」フォーム)/絞り込み(進行状況・遅延のみ)・並べ替え(納品日/進捗/状況/名前)・アーカイブ(archived_at,既定非表示)/ダッシュボード「要対応」自動抽出(納品遅延・納品間近7日・工程遅れ・要請求・入金待ち)/スマホ最適化(新規UI折返し+viewport)。全て本番反映+ブラウザ検証済。
- **採寸データNotion連携(2026-06-15)**: 案件詳細に採寸を表示(Notion→アプリ読取)。Notion採寸DB=`197f0338a7bf80d09ad1cc79b3425d62`(data source 197f0338-a7bf-8097-9782-000bf8355d6f「採寸データ」)。`制作プロジェクト`relationで案件逆引き→メンバー別 身長/B/W/H/肩幅/二の腕/手首/首/靴サイズ/採寸日/希望デザイン等。API `/api/measurements?projectId=<案件Notionページid>`。**インテグmimi-anken-kanri-syncに採寸DBの共有を追加必須**(projectsDBとは別共有、無いと404)。env `NOTION_MEASUREMENTS_DB_ID`で上書き可(既定コード内)。
- **Notion並行運用 完了(2026-06-13)**: アプリ→Notion一方向同期稼働。Notion案件DB=「プロジェクト【mi-mi】」(page/db `d376b2247feb4cfebd18cdd5f82fc73e`, data source `d3cf52e4-eec9-41b6-bb90-ec34bf9ba3f3`, title「衣装制作プロジェクト」65プロパティ)。内部インテグレーション「mimi-anken-kanri-sync」(token ntn_… はVercel env + web/.env.localのみ、gitには無し)を案件DBに接続。`web/lib/notion-sync.ts`が安全項目(案件名/着数/完パケ納品日/状況メモ/DE初・DE完・TC・FG・納品・SNS掲載【DONE】チェック/工程日付)のみPATCH、進行状況・請求管理(status型・語彙別)/リレーション/集計は対象外。projects-state POSTで編集案件だけpush。本番synced:1確認済。status対応表を作れば双方向化可。
- **Phase 3前半 稼働(2026-06-23)**: メール+パスワードの**個人ログインを実装・本番反映**(共有パスコード mimi2026 と**併用**)。Supabase Auth はまだ使わず、**認証情報を env `STAFF_LOGINS`(JSON配列)に格納する方式**を採用 ＝ **Supabaseに直接DDLを流す手段が無い**(supabase-jsはデータ操作のみ/CLI db push未リンク)ため、スキーマ変更を避けた。署名セッション(`web/lib/session.ts`)に本人情報(id/name/role/scope)を格納→`GET /api/me`でリロード復元。ログイン成功で本人に固定し本人選択画面をスキップ、非管理者は権限の自己切替禁止(roleLocked)、ログアウト=`DELETE /api/staff-auth`でCookie破棄。新規: `web/lib/staff-logins.ts`(PBKDF2/SHA-256照合)・`web/app/api/me/route.ts`・`web/scripts/hash-password.mjs`。**渡部勇気 yuki.watabe@someru.me = role=admin/scope=all(全権限)で発行済**。
  - **アカウント追加手順**: `cd web && node scripts/hash-password.mjs '<平文PW>'` でハッシュ生成 → Vercel env `STAFF_LOGINS`(Production, Sensitive)のJSON配列に `{id,name,email,role,scope,teams,hash}` を追記 → `npx vercel --prod` 再デプロイ。平文はrepo/envに残さない。ローカルは `web/.env.local` の `STAFF_LOGINS` に同形式。
  - **今後(Phase 3後半)**: 実スタッフ移行・Supabase Auth(auth.users)化・役割RLS(0002で有効化済、役割別ポリシー追加)。env方式はその時に置換。
- **見積・請求システム（2026-06-23・本番デプロイ済）**: MFの手入力を置き換える狙いで「見積請求」タブを新設。書類=見積/着手金(見積の50%)/納品後残金/全額/グッズ。テンプレ `web/lib/documents.ts`(衣装制作費/グッズ・税10%・登録番号T6011001142353・振込先 三井住友渋谷駅前・特別割引10%・納期短縮)は実請求書を1円単位で再現済。案件選択で取引先/件名/予算/着数(pieces)/メール(clientsから)自動補完。**自社で生成→メールでURL送付→開封追跡**: 公開トークンURL `?doc=<token>`(`DocumentView`/`/api/doc/[token]`はmiddleware免除)を取引先が開くと `document_opens` に開封日時記録→一覧に開封状況表示。**MFでは送らない**方針(ユーザー指示)。メール送付=**GAS(Gmail) accounting@someru.me 経由**(別プロジェクト `Claude プロジェクト/mimi-anken-mailer`、clasp管理、scriptId 1GKL49kADJSRtQZ…、Vercel env `GAS_MAILER_URL/GAS_MAILER_SECRET` 設定済)。スキーマ=`supabase/migrations/0006_documents.sql`(documents/document_lines/document_opens)。**★稼働に残る手動2点**: (1)0006をSupabase SQL Editorで実行(未適用だと/api/documents等500)、(2)GASメーラー初回承認(SETUP.md手順。someru.me Workspaceが匿名Webアプリ403で弾く場合はResend等に切替=GAS_MAILER_URL差替だけ)。送信未設定/失敗でも"URL発行"までは動く設計。
- **申請/備品/タスク 新機能(2026-06-24・本番稼働)**: サイドバーに「タスク/申請/備品」タブ追加。①申請フォーム=有給/早上がり/Liveいきたい(live_eventsから「行きたい」→参加申請、管理者承認)②備品発注管理(依頼→発注済→入荷)③タスク管理(各スタッフへ割当・状態サイクル)。スキーマ `0007_requests_supplies_tasks.sql`。API `/api/tasks`・`/api/requests`・`/api/supplies`・`/api/live-events`。UIは `web/app/_feature-tabs.tsx`(別ファイルでpage.tsx巨大化回避)。勤怠UIは優先度低で据え置き。
- **⚠ 運用上の重要事項(2026-06-24に痛い目)**: (1)**本番Supabase(無料枠)は数日放置で自動停止**しDBが落ちる→アプリのDB機能が無反応に(env認証ログインは生きるので気づきにくい)。再開はダッシュボード→Resume(数分)。運用するならPro化 or 定期ping。(2)**マイグレーション適用はブラウザのSQL Editor頼り**(psql/CLI/接続文字列が無いため)。手順=Monacoに `window.monaco.editor.getModels()[0].setValue(sql)` で流し込み→**本物のCmd+Enter**で実行(合成キーイベントは効かない)。SupabaseはGitHub OAuth(someru-3321既存セッション)でログイン可・MFA無し。確実化は `SUPABASE_DB_URL` を .env.local に入れてターミナル実行。(3)**Codexと並行作業すると事故る**: Drive同期で `* 2` 競合フォルダ・`.git/index.lock`残骸が発生。**着手前に他PC/Codexを止める**(`pgrep -i codex`/`ls .git/*.lock`)。
- **URL混同注意**: `mi-mi-project-management-site.vercel.app` は**旧Codex版デモ**(`_legacy-codex-app`, Viteフロントのみ・認証ハードコード `demo@someru.me`/`Someru0619`)で本番とは別物。本番は `mimi-anken-kanri.vercel.app`(`web/`)。
- **Phase 4/5**: Notion脱却(バックアップ機能は残す)・UX/検索/モバイル改善・本番公開。

タスクは harness の TaskList #5-7 に対応。
