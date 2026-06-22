# Sprint5 Specification

## Sprint Name

Museum Home

## Objective

Home画面をコレクションの管理画面ではなく、ユーザー自身のデジタルミュージアム入口として完成させる。

## Scope

- MY TOP 5
- コレクション総数
- 所有ブランド数
- お気に入り数
- 最近追加したスニーカー
- 最近履いたスニーカー
- ブランド別所有数

## MY TOP 5 Rules

- 詳細画面から手動で追加・解除する
- 最大5足
- お気に入りとは別に管理する
- 追加した順に展示する
- 並べ替え操作は将来対応とする

## Database Changes

Database version: 3 → 4

shoesテーブルに以下を追加する。

| Column | Type | Required |
| --- | --- | --- |
| top_order | INTEGER | NO |

## Completion Criteria

- 詳細画面からTOP 5を選択・解除できる
- 6足目を追加できない
- Home画面に選択したTOP 5が表示される
- コレクション集計が表示される
- ブランド別所有数が表示される
- 既存データを保持したままDBをversion 4へ移行できる
