# Kick×Kick アイコン仕様書（street テーマ）

## 目的
このファイルは、Kick×Kickアプリのアイコンを画像生成AIで作る際に、
どのAI・どのツールでも同じ基準で作れるようにするための仕様書。

## 共通仕様（全アイコン共通）

| 項目 | 内容 |
|---|---|
| 拡張子 | PNG（透過あり必須） |
| サイズ | 512×512px（正方形） |
| 余白 | 絵の本体は中央80%以内に収める（外側10%ずつは余白） |
| 影 | なし（フラットなデザイン） |
| 背景 | 透明 |
| 色 | 生成された色をそのまま使用（アプリ側で色を変える加工はしない） |
| テーマの方向性 | ストリート（グラフィティ、ストリートアート風） |
| 選択状態の表現 | 画像自体は1枚のみ。選択中は、アプリ側で「丸いオレンジのインジケーター背景＋1.15倍拡大」を自動で付ける（アイコン画像に選択/非選択の作り分けは不要） |

## アイコン一覧

| ファイル名 | 意味 | 参考（今のMaterialアイコン） | 状態 |
|---|---|---|---|
| nav_home.png | ホーム画面 | home | 未作成 |
| nav_sticker.png | ステッカーボード | sticky_note_2 | 未作成 |
| nav_add.png | 追加ボタン | add_circle | 未作成 |
| nav_collection.png | コレクション棚 | collections | 未作成 |
| nav_settings.png | 設定画面 | settings | 未作成 |
| appbar_dropdown.png | ボード/棚名の切替表示(▾) | arrow_drop_down | 未作成 |
| appbar_share.png | 共有ボタン | ios_share_outlined | 未作成 |
| appbar_menu.png | ハンバーガーメニュー | menu | 未作成 |
| appbar_add.png | 追加ボタン | add | 未作成 |
| icon_add_photo_large.png | 写真を追加(大きめ、靴登録・靴詳細) | add_a_photo_outlined | 未作成 |
| icon_add_photo_small.png | 写真を追加(小さめ、靴詳細) | add_photo_alternate_outlined | 未作成 |
| icon_trophy.png | TOP5・お気に入り関連 | emoji_events_outlined | 未作成 |
| icon_collection_box.png | コレクション概要(ホーム画面) | inventory_2_outlined | 未作成 |
| icon_restore_backup.png | バックアップ復元(設定画面) | restore_outlined | 未作成 |

## 保存先
assets/icons/street/ 以下に、上記のファイル名で保存する。

ファイル名の接頭語について:
- nav_ : 下部ナビゲーションバー用
- appbar_ : 各画面上部のAppBar用
- icon_ : 画面の中に配置される、個別の一般的なアイコン用
今後アイコンを追加する場合も、この接頭語のルールに従うこと。

## 更新履歴
- 2026-07-05: 初版作成（下部ナビゲーション5個、streetテーマのみ）
- 2026-07-05: AppBar主要ボタン4個(共有・メニュー・追加・切替)を追加、合計9個に
- 2026-07-05: 画面内の個別アイコン5個(写真追加大/小・トロフィー・
  コレクション概要・バックアップ復元)を追加、合計14個に
