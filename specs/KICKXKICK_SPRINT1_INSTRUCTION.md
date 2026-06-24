# Kick×Kick Sprint1 Implementation Instruction

## 1. 目的

この指示書は、Codex / Copilot に渡して Kick×Kick Sprint1 を実装するためのものです。

Sprint1では、Kick×Kickの最小コアを作成します。

最優先は、

- スニーカーを登録できる
- 登録したスニーカーを一覧で見られる
- 詳細画面を開ける
- 写真を表示できる
- TOP5に登録できる
- 着用履歴を記録できる

ことです。

Collection編集、Sticker生成、背景削除、PNG出力、バックアップはSprint1では実装しません。

## 2. 前提

既存リポジトリ:

```text
popchami/solemuseum
```

採用方針:

- Flutter
- Dart
- Material 3
- Riverpod
- ローカル保存優先

アプリ名は Kick×Kick として扱います。

## 3. 参照する仕様書

以下の仕様を前提にしてください。

```text
specs/KICKXKICK_SPEC.md
specs/KICKXKICK_PRODUCT.md
specs/KICKXKICK_UI_SPEC.md
specs/KICKXKICK_DATA.md
specs/KICKXKICK_DB_SPEC.md
specs/KICKXKICK_ROUTING_SPEC.md
specs/KICKXKICK_SPRINT_PLAN.md
```

## 4. Sprint1で作る画面

### 4.1 Main Navigation

Bottom Navigation:

- Home
- Collection
- ＋
- Sticker
- Settings

中央の＋はスニーカー追加導線とする。

Sprint1では Collection / Sticker / Settings は空状態でよい。

### 4.2 Home Screen

表示内容:

1. TOP5
2. 最近追加したスニーカー
3. Statistics簡易表示

Sprint1ではCollection / Stickerのプレビューは簡易カードまたは空カードでよい。

### 4.3 Sneaker List / Recently Added

登録済みスニーカーを表示する。

最低表示項目:

- メイン写真
- ブランド
- モデル
- Display Title（あれば）
- 着用回数
- 状態

### 4.4 Sneaker Form

新規登録 / 編集兼用。

必須:

- 写真
- ブランド
- モデル

任意:

- サイズ
- サイズ単位
- カラー
- 購入日
- 購入価格
- 購入先
- Display Title
- ステッカーテキスト
- 状態
- メモ

Sprint1では写真は1枚だけでもよい。
最初の写真は `side` 扱い。

### 4.5 Sneaker Detail

表示項目:

- 写真
- ブランド
- モデル
- Display Title
- ステッカーテキスト
- サイズ
- カラー
- 購入日
- 購入価格
- 購入先
- 状態
- メモ
- 着用回数

操作:

- 編集
- TOP5に追加
- 今日履いた
- 過去日追加
- 削除（Sprint1では確認のみ、完全なゴミ箱実装は後回し可）

### 4.6 TOP5

- 最大5足
- Sneaker Detailから登録
- 6足目選択時は入れ替え対象を選ぶ
- Home上部に表示
- 👑アイコンを表示

お気に入り機能は作らない。
TOP5に統一する。

### 4.7 Wear History

記録:

- 今日履いた
- 過去日追加

保存内容:

- 日付のみ

仕様:

- 着用回数は履歴数から自動計算
- 履歴削除で回数減算
- 初回着用で状態が `new` の場合、`worn` に自動変更

## 5. Sprint1で作るデータモデル

DB仕様は `specs/KICKXKICK_DB_SPEC.md` を参照。

Sprint1対象:

```text
sneakers
sneaker_photos
wear_histories
top5_items
app_settings
```

### 5.1 Sneaker

必要項目:

```text
id
brand
model
size
size_unit
colors
purchase_date_value
purchase_date_precision
purchase_price
purchase_source
display_title
sticker_text
status
memo
created_at
updated_at
deleted_at
```

status:

```text
new
worn
parted
```

### 5.2 SneakerPhoto

必要項目:

```text
id
sneaker_id
category
file_path
created_at
updated_at
```

Sprint1では category は `side` のみでもよい。

### 5.3 WearHistory

必要項目:

```text
id
sneaker_id
worn_date
created_at
```

### 5.4 Top5Item

必要項目:

```text
id
sneaker_id
rank
created_at
updated_at
```

rankは1〜5。

### 5.5 AppSettings

Sprint1で使う項目:

```text
has_completed_onboarding
is_premium
created_at
updated_at
```

## 6. 状態管理

Riverpodを使用する。

推奨Provider:

```text
sneakerProvider
sneakerListProvider
sneakerDetailProvider
wearHistoryProvider
top5Provider
appSettingsProvider
```

Repository層を分ける。

推奨Repository:

```text
sneakerRepository
photoRepository
wearHistoryRepository
top5Repository
settingsRepository
```

## 7. 画面遷移

Sprint1で必要な遷移:

```text
Home
↓
Sneaker Detail

FAB
↓
Sneaker Form
↓
Sneaker Detail

Sneaker Detail
↓
Edit
↓
Sneaker Form
↓
Sneaker Detail

Sneaker Detail
↓
Add to TOP5

Sneaker Detail
↓
Wore Today

Sneaker Detail
↓
Add Past Wear
```

## 8. デザイン方針

カラー:

- Black
- White
- Gray
- Orange

比率:

- 90% モノクロ
- 10% オレンジ

フォント:

- Plus Jakarta Sans
- Noto Sans JP

Sprint1では完全再現よりも、黒・白・グレー基調にオレンジをアクセントとして使うことを優先する。

## 9. Sprint1で実装しないこと

以下は実装しない。

- Collection棚編集
- Collectionスロット吸着
- Sticker Board自由配置
- ステッカー生成
- 自動背景削除
- PNG出力
- バックアップ
- 復元
- Premium購入処理
- ブランド / モデルマスタ
- SNS共有
- 通知

## 10. 完了条件

Sprint1完了条件:

- アプリが起動する
- Bottom Navigationが表示される
- FABからスニーカー登録画面を開ける
- 写真・ブランド・モデルを登録できる
- 登録済みスニーカーがHomeまたは一覧に表示される
- 詳細画面を開ける
- 編集できる
- TOP5へ登録できる
- Home上部にTOP5が表示される
- 今日履いたを記録できる
- 過去日を追加できる
- 着用回数が履歴数から表示される
- 初回着用で状態が新品から着用済みに変わる

## 11. 実装後に報告すること

作業後、以下を報告してください。

- 作成 / 更新したファイル一覧
- 実装した画面
- 実装したProvider
- 実装したRepository
- まだ未実装の項目
- `flutter analyze` の結果
- 実機 / エミュレータ確認結果

## 12. 注意

Kick×Kickは管理アプリではなく、スニーカーをデジタルステッカー化して飾るアプリです。

ただしSprint1では、飾る機能に入る前の土台として、スニーカー登録・詳細・TOP5・着用履歴を完成させます。