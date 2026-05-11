---
name: Obsidian記憶テンプレート
description: Obsidian で ⌘⇧M → memory-entry を選ぶと Claude記憶ファイルを作成しMEMORY.mdに自動追記
type: reference
---

**使い方**:
1. Obsidian で `⌘⇧M` (Templater: Create new note from template)
2. テンプレート選択 → `memory-entry`
3. プロンプトに沿って入力:
   - **記憶タイプ**: user / feedback / project / reference から選択
   - **ファイル名スラッグ**: `project_xxx` `user_xxx` 等 (拡張子なし)
   - **人間用タイトル**: MEMORY.mdに表示される名前
   - **一行説明**: MEMORY.mdのインデックスに載る一行
4. 本文を編集して保存
5. Obsidian Git が10分以内に自動コミット&push

**ファイル配置**:
- テンプレート本体: `Templates/memory-entry.md`
- 生成先: `00 Claude Instructions/memory/<slug>.md`
- インデックス: `00 Claude Instructions/memory/MEMORY.md` に自動追記

**追加情報**:
- 既に同名スラッグが存在する場合は上書きせず通知のみ
- 各プロンプトでキャンセル(Esc)するとそこで処理中断、ファイル未作成
- 本文(frontmatter下)は自分で書く必要あり
