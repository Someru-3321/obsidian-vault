---
name: feedback-tool-dead-end-escalation
description: 確認ツール(Chrome MCP/WebFetch/WebSearch等)が行き詰まったら粘らず早期にユーザーへ状況報告して方針を仰ぐ
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e8e5e27-2dda-4ba2-921c-54077267e50e
---

確認・取得ツールで目的の情報が2回続けて取れなかったら、別タブ・別URLを闇雲に試し続けない。何が取れて何がダメだったかを整理し、ユーザーに報告して進め方を選んでもらう。

**Why:** 2026-06-11 アイドルリストの保留再チェックで、Chrome MCP が screenshot 描画不可・X未ログイン・独自サイト権限外・WebSearch は US-only と確認手段が連続で行き詰まったのに、数ターンにわたってタブを作り直し・別URLを試し続け、時間を浪費したうえユーザーを不安にさせた（「ちょっと怖い」と言われた）。ハーネスのフックにも「stop cycling through browser tabs」と止められた。確実な結果を出せない手段を繰り返しても精度は上がらず、不信感だけ増える。

**How to apply:** 取得失敗が2回続いたら一旦止めて「取れたもの / ダメだったもの / 考えられる代替（別ブラウザ・ログイン状態の確認・手動分担・手元の既存情報で判定）」を提示し、ユーザーに決めてもらう。特にブラウザ自動操作は画面が見えるぶん不安を与えやすいので、早めに透明化する。複数ブラウザがある時は最初にログイン状態を確認してから着手する。[[project-idol-list-schedule-check]]
