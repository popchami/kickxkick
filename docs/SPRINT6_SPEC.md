# Sprint6 Specification

## Sprint Name

Backup Foundation

## Objective

オンラインアカウントを使わず、ユーザーがコレクションデータをJSONファイルとして手元に保存・復元できるようにする。

## Backup Scope

Included:

- Brands
- Shoes
- Favorites
- MY TOP 5 order
- Wear history

Excluded:

- Photo files
- Photo metadata
- Cloud storage
- Automatic backup
- ZIP packaging

## Format

- File type: JSON
- Format identifier: solemuseum-backup
- Format version: 1
- Generated timestamp included

## Export Flow

1. Settingsからバックアップ作成を選択
2. アプリ内ドキュメント領域にJSONを作成
3. OSの共有画面から保存先を選択

## Restore Flow

1. JSONファイルを選択
2. 形式とバージョンを検証
3. データ置換と写真対象外の警告を表示
4. 確認後、トランザクション内で復元
5. 画面データを再読み込み

## Safety Rules

- 不明な形式・バージョンは拒否する
- 必須フィールドがないデータは拒否する
- 復元処理はSQLiteトランザクション内で行う
- 復元前にユーザー確認を必須とする

## Completion Criteria

- JSONバックアップを作成・共有できる
- 正しいJSONを選択して復元できる
- 不正なファイルを拒否できる
- 復元失敗時に途中状態を残さない
- 写真が対象外であることを明示する
