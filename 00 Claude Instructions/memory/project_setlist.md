# セットリスト自動入力システム

## 概要
最果てのハイライトのライブ毎セットリストを携帯から送るだけでGoogleスプレッドシートに自動反映するシステム。

## 構成
- **スプレッドシート**: https://docs.google.com/spreadsheets/d/1-awIoO8U5-Yy4PAfgLe07z0ioOZt8QTO0thGvcns37w/edit
- **Apps Script (entertainment@someru.me)**: scriptId `10wG-m4oyndpQWqgnjX6P3vN_DBRIovRMIkBXn8WJYkuiN2ONiZKbRUpG`
- **Web App URL (公開、ANYONE_ANONYMOUS)**:
  `https://script.google.com/macros/s/AKfycbwVXCZqv3_gJGRZYDiUpcBvX1AzUfFIP1mTgUXLJF3nF6jAhULrxOYa2LuZsOHCpFA/exec`
- **ローカルコード**: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/setlist-script/` (clasp で管理)
- **Claude Code スキル**: `~/.claude/skills/setlist/SKILL.md` (略称→Web App URL の橋渡し)

## エンドポイント
- `?action=insert&text=<URL-encoded>` → 新シート作成
- `?action=inspect` → シート一覧 + 直近ショーシート
- `?action=inspect_show&name=<name>` → 特定シートの詳細
- `?action=delete_sheet&name=<name>` → シート削除
- POST `{text:...}` → insert と同等

## 仕様
- 略称マッピングは `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/setlist-script/master.gs` の `SONG_ALIASES`
- MC変換: 1分→MC -short-、2分→MC、最後のMCは MC -end- に自動変換 (例外: 末尾敗北者はスキップ)
- SE 自動先頭追加、きっかけ自動判定、曲順 ①〜 自動付与
- 新会場はマスタの会場リストに自動追加
- 新規シートはマスタシート直後 (最左) に挿入

## ユーザのフロー
1. 携帯で Claude (Claude.ai/Claude Code/etc) を開く
2. セットリスト本文を貼り付け
3. Claude がスキルに従って Web App を叩く
4. 結果のシートURLが返る

## 既存データの形式
- マスタ: シート「マスタ用」、A列=曲名、B列=曲調、C列=照明、D列=Time、E列=BPM、F列=曲構成、G列=作詞作曲
- 各ショー: 別タブ、タブ名は `YYYY/MM/DD` 形式 (推奨) / 旧形式 `YYMMDD` 等
- 曲ブロックは5行×11列、曲名以外の値は XLOOKUP で自動入力
- 会場リスト: シート「リスト」 A列、入力規則あり (新会場はリスト追加が必須)

## 更新方法
```sh
export PATH=$HOME/.local/node/bin:$PATH
cd ~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Claude プロジェクト/setlist-script
clasp push --force
clasp update-deployment AKfycbwVXCZqv3_gJGRZYDiUpcBvX1AzUfFIP1mTgUXLJF3nF6jAhULrxOYa2LuZsOHCpFA
```

## 認証
- clasp は entertainment@someru.me で認証済み (~/.clasprc.json)
- Web App は ANYONE_ANONYMOUS で公開、URLが秘密
