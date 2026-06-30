---
name: project-gyomu-itaku-payslip
description: 業務委託スタッフの給与明細(支払明細書)PDFの作成・保存先・命名規則と、Sheets→PDF→Drive投入の手順
metadata: 
  node_type: memory
  type: project
  originSessionId: 6de8f683-73cc-4d9c-8540-96f8d07c0c43
---

# 業務委託 給与明細 PDF の作成と保存

毎月の業務委託スタッフ給与明細(支払明細書)の作成・ファイリング業務。

## 元スプレッドシート
- 「給与計算【mi-mi/業務委託】」 id `1VCScOgT2ODh1Q9VwqZCJ3JureheDqrodEuJdrxbRfdQ`
- スタッフ×月ごとにシート(タブ)。タブ名は `26.4 インターン 岩尾祐芽` のように `{年.月} [インターン] {氏名}`
- インターンは「支払い明細書(mi-mi)」テンプレ。日払いは F7=`=日給*C11`(参加時間=日数)、源泉徴収 F9=`=sum(F7,F8)*10.21%`
- 振込先(E12, E12:F13結合セル)はセル内改行が必要 → GAS `String.fromCharCode(10)` で組み立て `setValue` が確実

## 保存先(Drive)
- **共有ドライブ/人事関連/給与関係/業務委託 明細/{氏名}/** にスタッフ別サブフォルダ
- ローカル同期パス: `/Users/yuki/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/共有ドライブ/人事関連/給与関係/業務委託 明細/`
- ファイル名は **`給与計算【mi-mi_業務委託】 - {タブ名}.pdf`**(スラッシュは自動で `_` に変換される)

## Sheets→PDF→Drive 投入手順(OAuth/base64不要の確実版)
1. ブラウザを export URL へ navigate するとPDFが `~/Downloads` にDLされる:
   `https://docs.google.com/spreadsheets/d/{id}/export?format=pdf&gid={gid}&size=A4&portrait=true&fitw=true&gridlines=false&printtitle=false&sheetnames=false&top_margin=0.5&bottom_margin=0.5&left_margin=0.5&right_margin=0.5`
   DLファイル名が自動で命名規則通り(`給与計算【mi-mi_業務委託】 - {タブ名}.pdf`)になる
2. `qlmanage -t -s 1400 file.pdf -o /tmp/` でサムネPNG化→Readでレイアウト確認(pdftoppm無いので)
3. 上記Drive同期フォルダ(該当サブフォルダ)に `cp` → Drive for Desktopがクラウドへ自動同期
- 注意: ページ内fetchはexportが googleusercontent へリダイレクトしCSPで弾かれる("Failed to fetch")。GASのDriveApp/UrlFetchAppはOAuth承認ポップアップが別ウィンドウでMCP操作不可。→ **DL→ローカル同期フォルダへcp が最も確実**

関連: [[invoicing_rules]] [[project_yuritsun_payment_journal]]
