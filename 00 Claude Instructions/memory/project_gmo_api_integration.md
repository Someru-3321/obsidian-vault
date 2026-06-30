---
name: gmo-api-integration
description: GMOあおぞらネット銀行API連携(参照系/Notion連動)の申込。2026-06-10にヒアリングシート兼チェックリスト提出済み。
metadata: 
  node_type: memory
  type: project
  originSessionId: 6b92dcd3-2bb5-4744-92aa-36f4f2efe065
---

染める株式会社がGMOあおぞらネット銀行のオープンAPI連携を申込中。窓口は田上うらら様(営業本部インサイドセールス、u-tanoe@gmo-aozora.com / Cc insidesales@gmo-aozora.com)。

- **アクセス種別**: private / 参照系(自社口座の入出金明細を参照)
- **目的**: 口座入出金をNotionに連携し入金照合・請求管理を自動化([[project_payment_check]] [[project_gmo_deposit_watcher]] の発展)
- **API連携対象口座**: GMOあおぞら 法人営業部(支店コード101)・普通・**1701470**・名義 染める株式会社。※[[project_gmo_deposit_watcher]] の mi-mi plus口座(2439067)とは別の法人代表口座。
- **2026-06-10 提出済み**: 「API連携ヒアリングシート兼API接続チェックリスト(参照系)」の両シートを記入し田上さんへメール返信。記入済みxlsxは `~/Downloads/gmo_api_unzip/` とマイドライブ直下。チェックリスト17項目はSaaS構成(Notion/Google Apps Script)・小規模・代表1名を前提にYes/No判断。No=Sec-16/20/26/39は②欄でSaaS構成・自社サーバ無しを説明。
- **情報セキュリティ管理規程(簡易版)**: Sec-3/4/7/8をYesにする根拠として `~/Downloads/染める株式会社_情報セキュリティ管理規程.docx` を作成。未提出、銀行から求められたら提出する想定。
- **次ステップ**: 田上さんの返信・補完審査待ち。API仕様書は開発者ポータル(https://api.gmo-aozora.com/ganb/developer/api-docs/)で要登録閲覧。
- **技術メモ**: 配布zipはパスワード付き＋CP932ファイル名。Pythonの zipfile で `info.filename.encode('cp437').decode('cp932')` で文字化け回避して展開。Excelはシート保護ありだが入力欄はロック解除済み・パスワード無し。AppleScript(`set value of range ... of worksheet ...`)でレイアウトを崩さず記入できた。
