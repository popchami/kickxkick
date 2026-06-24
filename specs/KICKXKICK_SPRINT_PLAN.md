# Kick×Kick Sprint Plan v1.0

## 1. 目的

この仕様書は Kick×Kick の実装順序を定義する。

仕様が増えても、開発順がぶれないようにする。

## 2. 開発方針

Kick×Kickは以下の順で作る。

1. スニーカーを登録できる
2. 登録したスニーカーを見られる
3. TOP5と着用履歴を使える
4. Collectionに並べられる
5. Sticker Boardで貼って遊べる
6. PNG出力・バックアップを追加する

最初から全機能を作らない。

## 3. Sprint 1: Core Sneaker MVP

### 目的

Kick×Kickの土台を作る。

スニーカーを登録し、一覧・詳細で見られる状態にする。

### 実装対象

- Bottom Navigation
- Home
- Collection空画面
- Sticker空画面
- Settings空画面
- 中央FAB
- スニーカー登録
- スニーカー一覧
- スニーカー詳細
- 靴写真1枚
- TOP5
- 着用履歴
- Statistics簡易表示

### DB対象

- sneakers
- sneaker_photos
- wear_histories
- top5_items
- app_settings

### 登録項目 MVP

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

### 完了条件

- スニーカーを登録できる
- 登録したスニーカーが一覧に出る
- 詳細画面を開ける
- 写真が表示される
- TOP5に登録できる
- 着用履歴を追加できる
- 着用回数が増える
- 初回着用で新品から着用済みに変わる

### やらないこと

- Collection編集
- Sticker生成
- 背景削除
- PNG出力
- バックアップ
- Premium購入処理

## 4. Sprint 2: Collection MVP

### 目的

Collection = 博物館 / 展示棚 の体験を作る。

### 実装対象

- Collection表示
- 棚一覧
- 棚追加
- 棚削除
- 棚名編集
- 背景テーマ選択
- スニーカー追加
- スロット吸着
- 並び替え
- 倍率変更
- 箱表示ON/OFF
- 最後に見ていた棚を記憶

### DB対象

- collections
- collection_items
- box_photos
- app_settings

### 完了条件

- 棚を表示できる
- スニーカーを棚に追加できる
- スロットに整列表示される
- 同じスニーカーを複数棚に置ける
- 倍率2〜5足表示を切り替えられる
- 前回倍率を記憶する
- 最後に見ていた棚を開ける
- 箱写真がある場合のみ箱表示を切り替えられる

### やらないこと

- Sticker Board
- ステッカー自由配置
- 背景削除
- PNG出力
- バックアップ

## 5. Sprint 3: Sticker MVP

### 目的

Kick×Kickの中心価値である「貼って遊ぶ」を作る。

### 実装対象

- Sticker Board表示
- Board一覧
- Board追加
- Board削除
- ステッカー生成 Normal
- 簡易背景削除
- プレビュー
- 簡易修正
- ステッカー配置
- ドラッグ移動
- 長押し回転
- ピンチ拡大縮小
- 固定 / 解除
- 重なり順変更
- 複製
- 削除
- Undo / Redo 30回
- 最後に見ていたBoardを記憶

### DB対象

- stickers
- sticker_boards
- sticker_board_items
- app_settings

### 完了条件

- 写真からNormalステッカーを作れる
- ステッカーをBoardに貼れる
- 移動・回転・拡大縮小ができる
- 固定 / 解除できる
- 複製できる
- 削除できる
- Undo / Redoできる
- 最後に見ていたBoardを開ける

### やらないこと

- Chibi
- Cartoon
- Pixel
- Hologram
- 高度な画像編集
- LINEスタンプ連携

## 6. Sprint 4: Premium / Export / Backup

### 目的

Premium価値と保全機能を作る。

### 実装対象

- Free制限
- Premium判定
- Premium誘導
- PNG出力
- ゴミ箱
- 復元
- バックアップ
- 復元
- Settings詳細
- Onboarding再表示
- Legal導線

### DB対象

- trash_records
- app_settings
- backup export data

### Free制限

- スニーカー5足まで
- Collection 1棚
- Sticker Board 1枚
- 1足につき1ステッカー
- Freeテーマのみ
- Freeフォントのみ

### Premium解放

- スニーカー無制限
- Collection無制限
- Sticker Board無制限
- 複数ステッカー作成
- PNG出力
- バックアップ
- 復元
- 全テーマ
- Premiumフォント

### 完了条件

- 6足目登録時にPremium誘導が出る
- 2枚目ステッカー作成時にPremium誘導が出る
- PNG出力できる
- ゴミ箱へ移動できる
- 30日保持ルールを実装できる
- 復元できる
- .kkbバックアップを作れる
- .kkbから復元できる

## 7. Sprint 5: Polish / Store Readiness

### 目的

ストア公開前の完成度を上げる。

### 実装対象

- UI調整
- アニメーション
- 空状態デザイン
- エラーメッセージ
- 課金説明文
- 利用規約
- プライバシーポリシー
- 権利表記
- ストア文言
- アプリアイコン
- スクリーンショット

### 完了条件

- 初見ユーザーが迷わない
- Freeでも価値が伝わる
- Premium導線が強すぎない
- 権利・商標方針を説明できる
- ストア提出に必要な最低限の素材が揃う

## 8. 実装しないもの / 後回し

MVPではやらない。

- ブランドモデルの完全マスタ化
- SNS連携
- LINEスタンプ正式連携
- AI生成ステッカー
- Chibi / Cartoon / Pixel
- 通知
- 売買機能
- 相場管理
- 資産管理
- クラウド同期
- 複数端末リアルタイム同期

## 9. 優先順位の原則

迷ったら以下を優先する。

1. スニーカーを登録できること
2. 写真がきれいに見えること
3. ステッカー化できること
4. 飾って楽しいこと
5. 管理機能
6. 課金機能

## 10. 最重要ルール

Kick×Kickは管理アプリではない。

Collectionは整列展示。
Stickerは自由配置。

実装順もこの思想を崩さない。