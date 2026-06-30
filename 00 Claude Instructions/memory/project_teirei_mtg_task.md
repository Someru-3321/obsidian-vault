---
name: project-teirei-mtg-task
description: 定例MTGテンプレのアジェンダ⇄タスク連携構築。Notion MCPのFILTER DSLはリレーション/自己参照を解決できない制約も記載。
metadata: 
  node_type: memory
  type: project
  originSessionId: 6af931cf-8c18-4d81-af37-3c17d76cbda3
---

mi-mi の「定例MTG」テンプレ（page `1d7f0338a7bf80f6983bc921c2688a6c` = 定例MTG data source の default_page_template）に、議題アジェンダからタスクを生やす連携を 2026-06-10 に構築。

データソース:
- 定例MTG: `collection://2d66fced-5042-4443-9124-7b1bb512d0d1`
- 定例アジェンダ: `collection://2d5f0338-a7bf-8007-b645-000b900edb76`
- タスク管理【mi-mi】All: `collection://238f0338-a7bf-81d4-9f0d-000b52494dd8`

追加したリレーション:
- 定例アジェンダ ⇄ タスク管理（双方向。アジェンダ側「タスク」/タスク側「アジェンダ」）
- タスク管理 → 定例MTG（一方向。タスクをMTGに直接紐付け）

テンプレ本体: アジェンダ表に「タスク」列を表示。「このMTGのタスク」インラインビュー(view `37bf0338-a7bf-81a3-b31d-000c25c68a7a`)を設置し、`定例MTG = そのページ自身` の自己参照フィルタ。テンプレ複製時に Notion が新ページURLへ自動書換（既存のアジェンダ表と同じ仕組み）。並びは アジェンダ→タスク→定例メモ。

**重要な制約**: Notion MCP の `notion-create-view`/`notion-update-view` の `configure` DSL `FILTER` は、select/status/number 等の値型は設定できるが、**リレーションの値を解決できない**（URL/ID/title いずれも空フィルタになる）。特にテンプレの自己参照リレーションフィルタは API 不可 → Notion UI（Chrome MCP）で手動設定した。`FILTER "優先度" = "高"` は可、`FILTER "定例MTG" CONTAINS "url"` は不可。

注意: 既存の各MTGページ（この変更より前にテンプレ生成済み = 例「定例MTG @今日 11:56」`37bf0338a7bf80e580c9dc4f5c4c7776`）には未反映。必要なら手動で同ビューを追加。
