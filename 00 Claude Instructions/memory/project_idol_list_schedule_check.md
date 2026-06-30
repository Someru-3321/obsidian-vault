---
name: project-idol-list-schedule-check
description: 🚈アイドルリスト(Notion)の公演日スケジュールチェック運用。未着地チェックと保留再チェックの手順・判定基準・ステータス振り分け
metadata: 
  node_type: memory
  type: project
  originSessionId: 0e8e5e27-2dda-4ba2-921c-54077267e50e
---

🚈 アイドルリスト DB: https://app.notion.com/p/55a5f085284f410599a04a089758e65e （親「イベント ブッキング管理」、data-source collection://46ece7ed-2e18-4dd4-bbd3-c0fd5bb07c70）。公演日ごとに status プロパティ `26.MMDD`（例 6/18=`26.0618`, 6/30=`26.0630`）。ビューは日付ごと（例 `v=364f0338…`=6/18ビュー、活動拠点・FW数でフィルタ）。fetch/queryの結果は巨大でトークン上限を超えるので、ファイル保存→python等でスライスして読む。

**「未着地のグループのチェック」**: status「未着地」(=未着手) のグループを、スケジュールURL/公式Xで対象日に予定があるか確認し振り分け:
- 対象日に予定あり → `AIチェック 予定有`
- 対象日が空き → `空き確認OK`
- 取得できない → `保留`

**「保留のグループを再チェック」**: 「保留」を再確認。スケジュール/Xで直近1ヶ月のライブ実績を見る:
- 1ヶ月ライブなし → `AIチェック 活動終了`
- 活動中で対象日の告知なし → `空き確認OK`

判定根拠は「【AI】チェック 根拠」プロパティに `YYYY/MM/DD …チェック: 内容 → ステータス` 形式で `<br>` 区切り追記（既存値をfetchして末尾に足す。上書きで履歴を消さない）。bio に「毎週◯曜配信」「◯月ワンマン決定」等があれば活動中の有力根拠。

活動終了の判定はデータ鮮度に注意: 根拠欄の「最終ポスト◯月◯日」は前回チェック時点の値のことがある。直近を直接確認できないまま終了断定せず「要再目視」を根拠に明記する。大量チェックは Workflow で並列化できるが、X画像スケジュールは screenshot 不可で読めないことが多い → [[feedback-tool-dead-end-escalation]]

**取得手段の実効性（2026-06-19 6/30東京ビュー445件チェックで確立）**:
- ビューは活動拠点でフィルタ済（「東京ビュー」は全445件が活動拠点=東京）。書き戻しは `26.MMDD` ステータス + 詳細を **「【AI】チェック 詳細」** プロパティに `<br>` 追記（このタスクでは根拠でなく詳細欄に集約された）。ステータス値の正確な文字列: `空き確認OK` / `AIチェック 予定有` / `保留`（既存optionと完全一致させる）。
- **WebFetch はほぼ無力**: アイドル公式サイトは TimeTree/GoogleCalendar埋込・Wix・SPA が大半で、サーバー側にスケジュール本文が無い。的中2割。
- **Chrome(claude-in-chrome)が本命**。手段の優先順:
  1. **TimeTree**(timetr.ee / timetreeapp.com/public_calendars/…): navigate→**screenshot**で月グリッドを直読。最も確実。会場がチップに無い時は当該日のイベントをクリック→イベントページURLに飛ぶので get_page_text で詳細（会場記載が無ければ「場所不明」）。
  2. **GoogleCalendar埋込**(calendar.google.com/embed?src=…): navigate→screenshotで月表示を直読。ただし**全体空のカレンダー＝非運用の可能性**なので空き断定せず保留。Cookie同意ブロックは同意せず保留。
  3. **SPA/FC公式サイト**(rizepro.net, scrambles.jp, babycrayonfc, shibu3.jp等): スクショはヘッダだけで空に見えても、**get_page_text が描画後のスケジュール本文(日付+イベント名)を抽出できる**ことが多い。これが効く。画像のみ(comiqon等)は「No text content」で取れず保留。
- 読めないまま残る典型: lit.link(リンク集で予定なし)・X画像スケジュール・壊れた空ウィジェット。Xはログイン済(@yukik_ba)でプロフィールは読めるが月間スケジュールは画像投稿が多く判読困難。
- **判定の機微（ユーザー基準厳守）**: 「6/30に予定はあるが会場/本数が東京か不明」は **予定有でなく『保留』**（基準「場所や本数が不明→保留」）。会場が東京と確認できて初めて予定有。空き扱いの見落とし防止が最優先で、未検証OK(空き確認OKのまま6/30未チェック)が最大リスク層。
- browser_batch は1アクションがエラーpage(サイトダウン)に当たると以降のスクショ画像ごと破棄される。4件/バッチ程度に抑えると被害が小さい。接続断は list_connected_browsers→select_browser で再選択(タブも取り直し)。

**地方ビューの「2回し」ルール（2026-06-20 大阪6/27ビュー70件で確立）**:
- 地方ビュー(v=36af0338…)は活動拠点=地方(関西/名古屋/九州/北海道/仙台/広島等)。**大阪/地元で1本だけの日は『空き確認OK』にしてOK**。理由=同日2回し(2公演目)を入れてもらえる可能性があるため。本数ベースで判定: **6/27が0〜1本→空き確認OK / 2本以上→AIチェック 予定有(本数・会場を詳細に記載) / 不明→保留**。会場が大阪外でも「1本だけ」なら空き扱い(2回し可)。
- 終日稼働系(ビアガーデン/カフェ型の専属ユニット=半熟王子・マイちゃんアミちゃん等、土曜1日複数ステージ)は2回し不可→予定有据え置き。
- **効率化の肝**: 既存「【AI】チェック 詳細」欄に前回チェックの「6/27に〇〇(会場)」が本数付きで残っていることが多い。**まず全対象の詳細欄をpythonで抽出し、本数が明記されているものは再フェッチせず新ルール(1本→空き/2本→予定有)を機械適用**。会場/地域不明で前回保留にしたものも「1本のみ」と読めれば空きに解決できる(例:片恋シンドローム IGNITIONmini 1本)。これで70件中41件を再取得なしで処理。
- 残る保留(URL未登録/lit.link Not Found/X判読不能)は公式X(列に格納済)を get_page_text で直読。ただし get_page_text は固定+最新1〜2件しか返さないので、6/27が固定や直近告知・月間まとめに載っているグループのみ解決可(フラサービ=固定に6/27 HACHI$LIVE / BudLaB=6月まとめに6/27なし→空き)。最新投稿が他日付(6/18・7/11等)や活動停止(2019〜2024で更新停止)のものは6/27確定できず保留据え置き。

**PRIMAL GLOW同事務所追加（2026-06-28）**:
- 既存: Tri-Sphere / Innocent Lucia は `事務所=PRIMAL GLOW`、`スケジュールURL=https://timetreeapp.com/public_calendars/pmglow` で登録済み。
- 新規追加: `GE'LMINATii`（公式X `https://x.com/Gelminatii`、活動状況/AI作動=活動終了、FW 1007、Mail `gelminatii@lasfactory.com`）と `つなかん！`（公式X `https://x.com/tsunakan1_ch`、活動状況/AI作動=活動中、FW 976、Mail `tsunakan1.gm@gmail.com`）。
- 2件とも `事務所=PRIMAL GLOW`、`活動拠点=東京`、`スケジュールURL=https://timetreeapp.com/public_calendars/pmglow`、`最新活動チェック日=2026-06-28`。

**事務所未登録の補完（2026-06-28）**:
- `事務所` 未登録は開始時1529件。既存の `事務所` セレクト選択肢にあるものだけ、公式X bio / Mailドメイン / スケジュールURL・公式URLドメイン / 既存DBの同一パターンから高確度で補完し、63件更新。終了時1466件。
- 補完した主な既存選択肢: `ASOBISHISUTEMU`, `RIZEプロダクション`, `LEADERS ENTERTAINMENT`, `タンバリンアーティスツ`, `株式会社imaginate`, `株式会社プリュ`, `HEROINS`, `プラチナムプロダクション`, `やばきゅーぶ`, `コレットプロモーション`, `IF FACTORY`, `マギマギ`, `DRAMATICAL RECORDS株式会社`, `株式会社シーメジャーワークス`, `boilover`, `HYPER MEDIA NEET`, `GMG Entertainment`, `セルフプロデュース`, `ONE5.inc`, `PRIMAL GLOW`。
- `WACK`, `SCOT`, `ESOLA MADE`, `I-GET`, `YU-M Entertainment`, `アップダンス・エンターテインメント`, `LIVE PLANET`, `SUKIYAKI RECORDS`, `サマリーエンターテインメント`, `ArcJewel` 等は `事務所` セレクトに選択肢がなく、追加なしでは更新不可。勝手にスキーマ変更せず保留。

**事務所セレクト追加込みの全体補完（2026-06-28）**:
- ユーザー指示「セレクトにないものは追加して」に従い、`事務所` select に不足選択肢を追加してから補完。DDLでは既存選択肢を全保持し、新規選択肢を末尾追加した。
- 追加した主な選択肢: `WACK`, `SCOT`, `ESOLA MADE`, `I-GET`, `YU-M Entertainment`, `アップフロントグループ`, `LIVE PLANET`, `アップダンス・エンターテインメント`, `SUKIYAKI RECORDS`, `サマリーエンターテインメント`, `ArcJewel`, `KABUKIMONO'DOGs`, `株式会社N-Rise`, `株式会社クリーブラッツ`, `Lil'inf`, `METEORA st.`, `モウソウプロジェクト`, `E TICKET PRODUCTION`, `Stand-Up! Records`, `Eureka Entertainment`, `FIND STAR RECORDS`, `株式会社オーバース`, `TWIN PLANET ENTERTAINMENT` など。
- 公式X bio / Mailドメイン / 公式サイト / 既存DB同一パターンから高確度なものを追加で98件更新。`事務所` 未登録は1529件 → 1391件。
- 注意: `NMB48` は古い `Showtitle` ではなく、2025-06-30以降の運営移管に合わせて `株式会社N-Rise` を使用。`シンセカイヒーロー` は `株式会社シンセカイヒーロー` ではなく公式所属根拠のある `株式会社クリーブラッツ` を使用。
- 残件は、個人プロデュース・自社/セルフ・個人所属・アイドル外ユニット・根拠が弱いメールドメインが中心。`X bio` に「所属」が残るものは `Unity`（メンバー個人の美少女図鑑所属）、`めり～ぽっぴん`（サウナ東京所属熱波師/自社経営）、`ヌガザカ`（アイドル外）で、事務所欄への反映は保留。

**Tear Rabbits同事務所追加（2026-06-29）**:
- `事務所` select に `Tear Rabbits` を追加。
- 既存更新: `ミリオン! 〜Million Heaven Tokyo〜`, `闇雲`, `最後の夏休み`, `Gの衝撃` を `事務所=Tear Rabbits`、`Mail=tearrabbits.official@gmail.com` に更新。
- 新規追加: `Goodbye for First kiss`（`事務所=Tear Rabbits`, `Mail=tearrabbits.official@gmail.com`, 公式X `https://x.com/stkiss_info`, URL `https://www.goodbye-for-first-kiss.com/`, スケジュールURL `https://www.goodbye-for-first-kiss.com/schedule`）。
- `闇雲` は URL/スケジュールURL を `https://www.yamikumo.info/` に更新。
