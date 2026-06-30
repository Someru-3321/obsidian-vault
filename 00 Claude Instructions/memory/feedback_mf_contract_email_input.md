---
name: MF契約 メール入力は execCommand を使う
description: MoneyForwardクラウド契約の送信先メール入力 React フォームに値を入れる時のワークアラウンド
type: feedback
originSessionId: current
---
MoneyForward クラウド契約の「送信先 > メールアドレス」フィールドは React 制御コンポーネントで、通常の `type` アクションや JS の `setReactValue` (HTMLInputElement.prototype.value setter + input event) では **React state に反映されない**。1文字目だけ state に残って、保存しても最初の1文字しか保存されない。

**症状**:
- DOM の `value` プロパティには正しい文字列が入っているように見える
- 表示上「メール形式が正しくありません」エラーが消えない
- 「保存して閉じる」してから開き直すと、最初の1文字だけ保存されている

**ワークアラウンド** (JS で実行):
```javascript
const email = document.querySelector('input[type="email"]');
email.focus();
email.select();
document.execCommand('delete', false);
document.execCommand('insertText', false, 'foo@example.com');
email.dispatchEvent(new Event('change', { bubbles: true }));
email.blur();
```
`document.execCommand('insertText', ...)` を使うと React の onChange ハンドラーが正しく発火し、内部 state も同期される。保存後にエラー表示も消えて 次へ ボタンが青になる。

**Why:** React Hook Form / Controller でラップされた input に対しては、ブラウザネイティブな input イベントを発火させる必要がある。`HTMLInputElement.prototype.value` の setter override では Hook Form の登録 ref を通った subscribe が動かない。

**How to apply:**
- MoneyForward クラウド契約の同意書作成で送信先メールを入れる時、必ず上記の execCommand 方式を使う
- 入力後は **必ず保存→開き直して値を確認** する。1文字だけ残ってないかチェック
- 入力後にエラーメッセージが消えること、次へ ボタンが青く active になることを確認
