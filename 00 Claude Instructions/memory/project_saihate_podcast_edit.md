---
name: project-saihate-podcast-edit
description: 最果てのハイライト 動画ポッドキャスト編集の自動化(カット+テロップ)。ツール群と素材構成・設計判断
metadata: 
  node_type: memory
  type: project
  originSessionId: 5b857831-58eb-42f6-a13b-4cfd2dc36360
---

最果てのハイライトの動画ポッドキャスト(月5本)編集を自動化するプロジェクト。目標=カット+テロップを極力自動化、最終調整はユーザーがPremiere Proで行う。

## ツール環境 (このMac, sudo無し/Homebrew無しで構築)
- 場所: `~/saihate-podcast/` (Google Drive外。venvにtorch等が入るためDrive汚染回避)
- venv: ffmpeg 7.0(static-ffmpeg・arm64), auto-editor 29.3.1, faster-whisper 1.2.1(large-v3)
- ffmpeg/ffprobe は static_ffmpeg のバイナリを venv/bin に symlink 済
- `run.sh <動画>` = 単一動画用パイプライン(saihate_edit.py: auto-editorでカット→cut.mp4 + Premiere XML、whisperでSRT)
- `transcribe_full.py <wav> <srt> <json>` = メイン音声を全文文字起こし(SRT+JSONセグメント)
- 注: system python は 3.9.6。Homebrewは管理者パスワード必須で非対話シェルから入れられなかったため static-ffmpeg で代替

## 素材構成 (重要)
- 場所: `/Volumes/creative/SH_ポットキャスト/<回>/` (外付け"creative"ドライブ)
- **多カメ(5台)** + **人ごとの個別マイクstem**(`SH ポットキャスト_N/Stems/`)。stem分離が自動化の最大の武器
- 第1回: 60fps, 約42分。カメラ=C0026/C0054/C0055/C3772/C3773、stem=メイン/永遠カフネ/ゆりつん/ひま1/ひま2
- Premiereプロジェクト=`SH_PS#1.prproj`、シーケンス書き出し=`SH PC #1.xml`(xmeml v4/FCP7形式)

## 検証で分かったこと
- **無音カットは不向き**: メイン全42分でauto-editorが削れたのは26秒(1%)のみ。5人ポッドキャストは常時誰か喋ってて無音が無い。テンポ編集は別アプローチ要
- **文字起こしは高精度**: large-v3で固有名詞(ゆりつん/ひま/永遠カフネ)も拾える
- **ffmpeg 7.0 が C0026/C3772/C3773 を開けない**(`error reading header / Not yet implemented`)。ただし多カメ自動スイッチ/XML出力は映像をデコードしないので**ブロッカーではない**(Premiereがレンダリング)

## 採用する自動化(ユーザー選択済)
1. 話者ラベル付きテロップ(stemごとのRMSで話者判定 + メイン文字起こし → 「名前: 発言」SRT)
2. 多カメ自動スイッチ(各マイク音量で発話者判定 → その人のカメラへ切替 → Premiere XML出力)。要: カメラ→人の対応表
3. AIカット提案(文字起こし全文をClaudeが読み退屈/脱線/撮り直しを抽出 → ユーザー確認 → 適用)
4. 無音/長い間のトリム(軽いテンポ調整)
- ブランドテロップ統一テンプレ(白青・モルフォ蝶)はテロップ生成後に作る。[[project-saihate-brand-info]]

## 実装状況 (第1回で構築完了・全部 ~/saihate-podcast/ )
- スクリプト: **speaker_attribute.py(話者帰属=発話単位・マイク別正規化。これが現行の高精度版)** / speaker_activity.py(旧フレーム方式・非推奨) / multicam_switch.py(自動スイッチXML生成・カット区間対応) / speaker_label.py(話者ラベルSRT・禁則処理・カット対応) / transcribe_full.py / finish_tail.py(部分結果の続きだけ処理) / parse_xml.py / brand_telop.py(ブランドテロップ=ミニマル版) / proof_switch.py(精度検証シート)
- 話者帰属の精度: 発話単位+マイク別ゲイン正規化が最良(ゆりつん42/ひま25/カフネ11/かぶり22%)。フレーム生(v1)やフレーム閾値(v2=かぶり41%で悪化)より良い。カット区間は multicam_switch/speaker_label の第4引数 "in-out"(秒) で指定→_cut版出力
- 出力 out/SH_PC1/: SH_PC1_autoswitch.xml(多カメ自動スイッチ・要Premiere取込テスト) / caption.srt / speakers.srt / name_tags.csv / main.json,srt(全文) / cut_suggestions.md(AIカット提案) / transcript_compact.txt
- 出力 out/brand/: name_<5人>.png / corner_*.png(コーナー名から自動生成) / caption_ref.png / preview.png
- カメラ実態: 5ファイル=3アングル(C0026=引き / C0054+C0055=ゆりつん / C3772+C3773=カフネ+ひま)。録画分割の隙間は引きにフォールバック。同期はXMLの音声トラックから抽出
- 文字起こしlarge-v3はCPUで実時間弱(42分で~40分)・落ちやすい→finish_tailで部分結果を活かす運用
- AIカット第1回の目玉: 23:28-25:03でひま本人が「編集して」と勧誘/スピ話のカット要請

## フルテロップ運用(第1回で確立・**2026-06-21に全面刷新=これが現行**)
- **最重要: 編集済み音声を直接 vad_filter=False で文字起こしする**。これがテロップ自動化の正解パイプライン。
  - 旧方式(生音声→XMLで編集時間に再マッピング=remap_telop.py)は**~11s変動ズレで失敗→廃止**。
  - **vad_filter(無音カット)をONにしてはいけない**: ①小声を無音判定して取りこぼす(文字起こし足りない) ②無音を詰めてタイムスタンプが圧縮され**変動ズレ**(手動でも直しきれない)。これが「ズレる/途切れる/内容違う」の真因だった。
- 現行スクリプト(~/saihate-podcast/):
  - `transcribe_one.py <音声> <出力dir> <名前>` = 編集音声(例 SH ps #1.mp3)を完全文字起こし。vad_filter=False・前後15sオーバーラップ採用範囲は重複なし(境界の語落ち防止)・隣接重複除去・再開可能(chunk_*/)。large-v3 CPUで35分≒30分。**caffeinate -i -s + バックグラウンド+Monitor監視**で落とさず完走。出力 edit_audio2.json/.srt(編集タイムラインに一致)。
  - `build_caption.py <segments.json> <出力.srt>` = REPL(誤変換/同音異義/会場正式名)→笑い(LAUGH)除外→句読点/助詞で自然分割(LINE=24)→**隙間を完全に詰める(各キューを次キュー開始まで保持・上限5s)** → SRT。喋ってる間テロップが消えない。
  - REPLは第1回分を多数登録済(他力本願/ディズニー/整番/赤点回避/敗北者/鬼滅/強欲/進研ゼミ/カフネちゃん/JET-R/掟/開演/払拭/取られた/方向音痴/にやけ顔/目覚まし時計/一発目+会場名)。回ごとに新出誤変換を追記する運用。
  - **カット同期(品質UP)**: 編集動画をffmpeg scene検出(`scale=320:-2,select='gt(scene,0.12)',showinfo`→pts_time→cuts.txt。4K35分で約9分・実時間の1/4)。build_caption.pyの第3引数にcuts.txtを渡すと、字幕の切り替わり(隣接キュー境界)を±0.5s以内のカットへスナップ=切替がカットに乗ってクオリティUP(第1回は209カット中152境界を吸着、隙間ゼロ維持)。ユーザー要望「テロップ切替はカットに合わせる」。
  - `preview_on_frame.py <動画> <srt> <出力dir> <秒…>` = 実フレームにPillowでキャプション焼いて目視検証(内容+アライメント確認用。ffmpegフォント問題回避)。
- 出力: **SH_PC1_telop_FINAL.srt(1082キュー・隙間ゼロ・全校正済)** が最終成果物。素材フォルダ + Drive にコピー。
- ひまの実マイクは **ひま2.wav**(ひま1は-37dBでほぼ無音の空きch)。話者ラベルはspeaker_attribute.py。
- テロップ推奨スタイル(Premiereキャプション): 白・細い縁取り(ネイビー1-2px)・薄い影。太い黒縁は不可(アーティスト感)。
- **Premiere差し替え手順(computer-use)**: 旧キャプショントラックヘッダ右クリック→「1つのトラックを削除」(映像音声に影響なし・Cmd+Zで戻る)→プロジェクトに新SRTをCmd+Iで再取込(同名は混同するので別名コピー推奨)→タイムラインへドラッグ→「新しいキャプショントラック」ダイアログで**開始点=ソースタイムコード**でOK→正しい位置に並ぶ→Cmd+S。**注意: "ユニバーサルコントロール"が頻繁に前面を奪う→各操作前に open_application でPremiere前面化**。バックスラッシュ等のツール切替キーは誤爆危険(全クリップ選択→削除事故)なので使わない。
- サムネ: build_thumb_artist.py(全面ポートレート+背景ぼかし+午前4時の青みグレード+控えめ文字)。メイン被写体=ひま。素材MP4(SH ps #1.mp4)はffmpegで読める(生カメC0026/C3772/C3773は不可)

## 切り抜き動画(縦型ショート)生成 — 第1回で確立 (2026-06-23)
- 目的: 1回の本編から面白い瞬間を縦型9:16ショート(TikTok @saihate_idol / Reels / YTショート)に量産。
- **ソース**: 編集済み `SH ps #1.mp4`(4K 3840x2160 / 59.94fps / ffmpegで読める)＋校正済み `out/SH_PC1/SH_PC1_telop_FINAL.srt`(編集タイムラインに完全一致)。この2つが揃ってれば切り抜きは全自動。
- **スクリプト**: `~/saihate-podcast/make_clips.py`。CLIPS=[(id, slug, フックタイトル, 開始cue, 終了cue)] をcue番号で指定→SRTをパースして時間を自動算出。`python make_clips.py [id...]`(引数なしで全部)。出力=`/Volumes/creative/SH_ポットキャスト/1/切り抜き/clipNN_slug.mp4`。
- **レイアウト(定番の安全形)**: 引き3ショットと1人アップが切り替わる編集なのでセンタークロップ不可(左右の発言者が切れる)。→ 背景=全画面をcoverスケール+boxblur+暗く、前景=16:9を幅1080(=1080x608)で中央(y=560)に配置、上にフックタイトル(\\N改行・白/紺縁)、映像帯の下にテロップ。誰が話してても切れない。
- **テロップ**: FINAL SRTのcueをクリップ毎に切り出し0基点へリベース→ASS化。`wrap_jp()`で約15文字毎に句読点/助詞優先で手動改行(libass自動折返しは効かない時があるので手動が確実)。フォント=Hiragino Sans(libassが自動発見、fontsdir不要)。白・紺縁(Outline 4)・薄影、Cap fontsize60。
- **ハマりどころ(重要)**: ①ASSの`[Events] Format`行に**Nameフィールド必須**。Dialogue側に空Name(`Style,,...`)があるのにFormatにName無いとフィールドがズレてテキスト先頭に`,`が漏れる。②改行は`\\n`(ソフト=スペース扱い)でなく`\\N`(ハード)。③長いcueは幅をはみ出して両端が切れる→手動wrap必須。
- **ffmpeg**: `-ss START -i SRC -t DUR`(入力シーク=フレーム正確・高速)→filter_complex(split→bg blur/eq + fg scale → overlay → ass)→libx264 crf20 preset medium 30fps + aac192k +faststart。4K60デコードで約1.2倍速(50sクリップ≒42s)。`caffeinate -i -s`+バックグラウンドで一括。
- **検証**: 出力からffmpegで数フレーム抜いてReadで目視(テロップ位置/折返し/全員映ってるか)。
- 第1回の採用切り抜き11本: 目覚まし時計/お嬢様疑惑(ディズニー16時)/シングルライダー娘その2/二郎系ギャップ/夜更かしバレ/初ライブハウス知恵袋/ラバーバンド30本/文化祭鬼滅サボり/公開謝罪/コラショ買取/鬼滅見たことない88点。

## 切り抜き v2 — 全画面+顔追従クロップ+大型テロップ (2026-06-24, ユーザー要望で刷新=現行推奨)
- ユーザー要望: ①話してる人にカメラが切り替わってほしい ②視覚性よく ③テロップもっとデカく。→ v1の「全員小さく帯+背景ぼかし」をやめ、**全画面9:16クロップ+カット毎に主要な顔へ寄る**方式へ。
- **スクリプト**: `~/saihate-podcast/make_clips_v2.py`(CLIPS/parse_srt/ass_time/wrap_jpはmake_clips.pyから再利用)。出力=`/Volumes/creative/SH_ポットキャスト/1/切り抜き_v2/`。
- **顔検出**: OpenCV `cv2.FaceDetectorYN`(YuNet)。モデル=`~/saihate-podcast/models/yunet.onnx`(232KB, opencv_zooからDL済)。`pip install opencv-python-headless`済(venv)。Haarは紫照明/横顔で取りこぼし多く不採用。YuNetは正面0.9前後で安定、横顔/下向き/wide左端は時々ミス(その区間は前ショットのxを継続)。
- **クロップ方式**: 編集マスターのカット時刻(`out/SH_PC1/cuts.txt`=編集TLの209カット)でショット分割→各ショットでサンプル(fps2.5・960px幅)の最大面積の顔のx中央値→crop window(幅1216=2160の9:16, 全高)のxをそこに合わせる→`ffmpeg sendcmd`でカット時刻にcrop xを瞬間切替(`{ts}-999 [enter] crop x {val};`)→scale 1080x1920→ass。**crop/sendcmd検証済**(crop filterはx,y,w,hがランタイムコマンド対応)。
- **限界(仕様)**: 画面に居ない人は出せない。編集マスターが話者でなくリアクション側を抜いてる場面(例clip08でひま語り中にゆりつん抜き)は、こちらもその画の人に寄る=元編集のショット選択を継承。完全な話者追従は編集マスター単体では不可。生カメC0026/C3772/C3773はffmpegで開けず(ゆりつんC0054/0055のみ可)→生から再スイッチも不可。改善余地: wide(顔3つ)区間だけ speaker_activity.json の話者→座席(左ひま/中カフネ/右ゆりつん)で顔を選ぶ。
- **テロップ大型化**: Cap fontsize 82・Outline7・Shadow4・wrap 11文字・MarginV235、Title 68・MarginV96。`wrap_jp`は行をバランスさせ1文字孤立(「〜だけ/ど」)を防ぐ版に改善済。BackColour半透明。
- v1(`切り抜き/`)=帯+ぼかし版も残存。

## 切り抜き v3 — バズる品質 (2026-06-24, ユーザー「完璧でクオリティ高い・バズる可能性のある動画に」→ 現行最終)
- **スクリプト**: `~/saihate-podcast/make_clips_v3.py`。出力=`/Volumes/creative/SH_ポットキャスト/1/切り抜き_v3/`。v2をベースに以下を追加。
- **カラオケ字幕(最重要・バイラルの肝)**: 文字レベルのタイムスタンプが `out/SH_PC1/edit_audio3.json`(faster-whisper word_ts, 各要素が1文字{w,s,e})に有り。これを使い ASS `\kf` で発話に合わせ **白→黄でワイプ**(Primary=黄&H0057D6FF=発話済み, Secondary=白=未発話)。cueの尺を文字数で按分(proportional)=校正テキストとずれない・堅牢。`karaoke()`関数。Cap fontsize86・Bold・Outline7・Shadow3・MarginV250。
- **顔追従を一段タイトに**: crop heightを2160→1880(幅1058)に詰め、顔のy中央も追従(`crop y`もsendcmdで切替、顔を上40%に置くバイアスで頭切れ防止)。検出は`detect_faces`がcx,cy返す。
- **ブランドハンドル**: `@saihate_idol` を右上に半透明小サイズ常時表示(Handleスタイル, alpha 0x64)。フォロー導線。
- **フックタイトル**: 上部70px白・強アウトライン、クリップ全体表示。
- 仕上がり: 全画面・カット毎に被写体へ寄る・カラオケ字幕・大型読みやすい・ハンドル付き。色を黄→モルフォ青に変えたい場合はCapのPrimaryColour差し替えのみ。
- 既知の限界はv2と同じ(画面に居ない人は出せない=元編集のリアクション抜きを継承)。長いcueは3行になる(fontsize大のため)。
- v1=帯ぼかし / v2=全画面顔追従 / v3=v2+カラオケ+タイト+ハンドル。

## 切り抜き v4 — テンポ重視・間カット (2026-06-24, ユーザー「とにかくテンポ高く・無駄な間はカット・伸びる動画に」→ 現行最終)
- **スクリプト**: `~/saihate-podcast/make_clips_v4.py`。出力=`/Volumes/creative/SH_ポットキャスト/1/切り抜き_v4/`。v3に「無音(間)自動カット」を追加。
- **間カット方式**: ffmpeg `silencedetect=noise=-30dB:d=0.30` で間を検出→前後 SIL_PAD=0.08s 残して `build_keep`でkeep区間化→`make_mapper`で旧t→新t写像。**ffmpeg `select/aselect` で映像音声を同一区間だけ残し `setpts=N/FRAME_RATE/TB`・`asetpts=N/SR/TB` で詰める**(ワンパス)。字幕cue・cropのsendcmd時刻を全部 mapper で新タイムラインへ再マップ→ズレなし。A/V差は累積でも~0.04s(無視可)。
- パラメータ調整: d大きい=保守的(d0.40で87s→82.8s)、d0.30で~7s/87sカット(現行採用)、d0.25は刻みすぎ注意。密な掛け合い(clip01等)は間が無く0カット=内容適応的に正しい挙動。
- カラオケ字幕は新タイムラインのcue尺で再按分。検証済(カット後もカラオケ/クロップ/字幕同期OK)。
## 切り抜き v5 — 話者追従強化・テンポ最大・カラオケ廃止 (2026-06-24, ユーザーFB反映 → 現行最終)
- ユーザーFB: ①話者への切替が甘い→もっと寄せたい ②もっと攻めたテンポ(d下げる) ③リアクション抜きのwide区間で話者に寄せたい ④カラオケ色は不要 ⑤女の子なのでドアップにせず"ちょっと寄った動き"があればOK。
- **スクリプト**: `~/saihate-podcast/make_clips_v5.py`。出力=`/Volumes/creative/SH_ポットキャスト/1/切り抜き_v5/`。
- **話者追従(wide区間のみ)**: `out/SH_PC1/name_tags.csv`(列=start,end,start_sec,end_sec,member / メンバー=永遠カフネ・ゆりつん・ひま / **編集タイムライン一致を検証済**)で各時刻の音声話者を取得。`choose_target`: 顔1つ=それ / **顔3つ以上(=wide)のみ 左右の並び順で座席判定(左=ひま・中=カフネ・右=ゆり)して話者の顔を選ぶ** / 2ショット・接写は最大の顔。絶対座標アンカーは2ショットで誤爆するので並び順方式に変更。clip08でひまの語り中にひまへ寄れるのを確認(v3/v4はゆりつん抜きだった)。
- **ゆる寄り**: CH=2050(ほぼ全高=ドアップ回避)、EMA=0.42でショット内は滑らか追従・カット(`crossed`)で即スナップ。crop x,y両方sendcmd。顔上42%に配置。
- **テンポ最大**: silencedetect d=0.25・pad=0.07(v4のd0.30より攻め)。clip08=87.3→79.0s(8.4sカット)。密な掛け合い(clip02=0.7s)は適応的に最小。
- **カラオケ廃止**: Cap=白単色(Primary/Secondary共&H00FFFFFF, \kタグ無し)。build_assはwrap_jpのみ。
- 既知の限界: 2ショットで話者が映ってない/最大顔が聞き手の場合は聞き手に寄る(wide以外は座席判定しない方針=ユーザー合意)。
- バージョン系譜: v1帯ぼかし / v2全画面顔追従 / v3+カラオケ+タイト+ハンドル / v4+間カット / **v5=話者追従(wide)+ゆる寄り+テンポ最大+白テロップ(現行最終)**。
- ⚠外付け"creative"ドライブはセッション中に外れることがある(/Volumesから消える)。素材も成果も全部このドライブ上→外れたらSRC読めず`os.makedirs(OUTDIR)`がPermissionErrorで落ちる。再接続待ちにすること。

## 最終形
素材投入 → カット済みPremiere XML + 話者ラベルSRT を出力 → ユーザーはPremiereで最終調整して書き出し。
切り抜きは make_clips_v2.py で縦型ショート(全画面+顔追従)を即量産(本編とは別系統)。

## 第2回 (フォルダ `2/`) 進捗 — 構成カット作業中 (2026-06-22、セッション中断・要再開)
- **タスク**: トーク全体の構成を見たカット編集。①導入が始まる前の雑談を全カット ②同じ話の繰り返しを圧縮 ③全体の流れを設計しながらカット。「一旦カットだけ」、テロップは後工程。メンバー3人=じぇと・永遠カフネ・アル。
- **ネスト構造(確定)**: トップseq「SH ps #2」(SH ps #2.xml) の V1=「マルチカメラ」ネスト1本(start 0..68634 ≈38分)、A1-A6=各カメラ音声(C0027引き/C3774-3775/C0057-0059)、A9-A11=個別マイクstem(file-6,7,8)。ファイル定義は全部ネスト(sequence-2)内部にあり、トップ音声は参照のみ。「ネストそのままカット」= マルチカメラ再編集せず全トラックを同一KEEP区間でリップルカット。
- **時間換算(重要)**: タイムライン0 = 録音(main_mix/stem) 176.6秒。F(タイムラインframe)=録音ts秒*FPS-5295。FPS=30000/1001、SEQ_END=68634、TICK=8475667200(=1frame分ticks)、stem in=5295。
- **cut_nest.py (検証済・完成、~/saihate-podcast/)**: `cut_nest.py <keep.json> <out.xml> [seq名]`。keep.json=[[k0,k1],...] タイムラインframe昇順。V1ネスト初回断片だけフル定義+以降は空id参照→ファイル定義二重化なし。ダミーKEEPで隙間ゼロ・尺一致を確認済。KEEP区間さえ決まれば即XML出力できる状態。出力先想定=/Volumes/creative/SH_ポットキャスト/2/SH_PC2_cut.xml。
- **文字起こし**: main_mix.wav=stem3本amix(BGM抜き・16k mono・41分, out/SH_PC2/)。高速版 transcribe_fast.py(medium/word_ts off/beam1/vad off)→ out/SH_PC2/chunks_fast/c_00-05.json。**⚠Whisperのハルシネーション(同語「はい。」無限ループ)混入の疑いが濃厚→構成判断前に要精査、または large-v3+word_ts+condition版(transcribe_one.py)で取り直し推奨**。build_analysis.py=chunks+speaker_segs統合→analysis.tsv(タイムライン内848/924seg)。
- **speaker_segs**: out/SH_PC2_speaker_segs.json (ep2_attribute.py生成、タイムラインframe単位の話者区間)。カット境界のスナップに使える。
- **次回の手順**: ①文字起こし品質を確認(ハルシネーション除去 or large-v3で取り直し) ②内容を精査して構成把握 ③KEEP区間決定→keep.json ④cut_nest.pyでXML ⑤Premiere取込で「ネスト分割断片の空id参照」が正しく解決されるか実機確認。
- **⚠このセッションの教訓**: ツールのstdoutが不安定でClaudeが結果を誤読(存在しない「完了」「1337seg」等を生成)する事故が多発。次回は **Bash stdoutを鵜呑みにせず、結果は必ずファイルに書き出し→Readツールで確認** する運用が安全。Read/Edit/Writeは安定。
