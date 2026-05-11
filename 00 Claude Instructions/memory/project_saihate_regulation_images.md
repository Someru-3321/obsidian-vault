---
name: saihate-regulation-images プロジェクト
description: 最果てのハイライト レギュレーション X投稿画像生成スクリプト (Pillow PNG + 自前SVG)。Canva 編集用 SVG も同時出力。
type: project
originSessionId: 526bf309-faa6-4317-880f-ddc087778b0d
---
最果てのハイライト (saihate.someru.me) のレギュレーション内容を X 投稿用画像 4 枚に整形して書き出すプロジェクト。染める株式会社所属バンドの運営告知用。

**Why:** ファンに特典会・SNS等のルールを視覚的に告知するため。レギュレーションが更新されたらこのスクリプトで再生成して X に投稿し直す運用。

**How to apply:**
- スクリプト: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/saihate-regulation-images/generate.py`
- レギュレーション原文: `http://saihate.someru.me/regulation/`
- 出力: PNG ×3枚 (X投稿用) + SVG ×3枚 (Canva編集用) — 全画像 1080×1609 (1:1.49) で統一
- ページ構成 (3枚):
  - 01: 特典会・物販 / Tokutenkai Rules (進行・参加方法・撮影ルール・禁止事項・撮り直し・各券)
  - 02: 特典・プレゼント / Benefits & Gifts (動員特典・LINEポイント・プレゼント)
  - 03: SNS・プライバシー / Posting & Privacy (投稿全般・会場情報・トラブル防止・AI制限・撮影写真投稿)
- デザイン: ダーク背景 #161513 + エメラルド差し色 #34A884 + ウォームオフホワイト本文
- フォント: ヒラギノ角ゴシック W3/W6/W8 + ヒラギノ明朝 (英字サブ)
- データ構造: 文字列 = 通常 bullet / `{"lead":..., "items":[...]}` = リード文＋サブ箇条書き
- 短い列挙は「/」区切り横並び (例: 「商用利用 / 加工・再販 / AI素材としての利用」)
- ユーザー好みのデザイン傾向 (重要): 装飾少なめ・エディトリアル組・タイトルの「・」だけアクセント色・左端縦アクセント線・「+」セクションプレフィックス
- 内容変更時は `pages` リストの content data を編集して `python3 generate.py` で再生成
