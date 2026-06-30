---
name: feedback-chrome-mcp-kanji-input
description: "Claude in Chrome の `type` アクションで難読漢字（梛、栞 等の異体字や2バイト常用外）が IME 変換で別字に化ける場合は JavaScript の execCommand('insertText') で直接挿入する"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c55fd1cd-4a2d-4942-8462-f525fc4f6b28
---

## 問題

Chrome MCP の `computer.type` アクションで「井上由梛」と入力したら「井上由梨」と化けた。
これは macOS の IME（日本語入力）が `type` で送られたキーストロークを変換解釈してしまうことが原因と思われる。

## 対処

入力欄をフォーカスした状態で `javascript_tool` を使い、`document.execCommand('insertText', false, '梛')` で該当文字だけ直接挿入する。

```js
(() => {
  document.execCommand('insertText', false, '梛');
})()
```

contenteditable や React 制御の textarea（LINE Official Account Manager 等）でも正しく入る。

## いつ気をつけるか

- 顧客名・社名・地名で難読漢字／異体字が入る入力。送信前に必ず画面で漢字を確認。
- 一文字でも違うと失礼にあたるので、宛名は最重要チェック。

関連: [[feedback-mf-contract-email-input]]（execCommand insertText の別ユースケース）
