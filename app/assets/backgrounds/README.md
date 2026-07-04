# 背景画像

アプリ全体・Sticker Board/棚の背景テーマ用の画像を置くフォルダです。

以下のファイル名で、縦向き専用の画像を配置してください。画像が無い間は
自動的にクリーム色（`0xFFF3E7D3`）にフォールバックし、エラーにはなりません。

- `background_orange.jpg` — オレンジテーマ
- `background_street.jpg` — ストリートテーマ

新しいテーマを追加する場合は、`lib/models/background_theme.dart`の
`BackgroundTheme` enumに1件追加し、対応するファイルをここに置いてください。
