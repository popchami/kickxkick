# Kick×Kick Data Changelog


## 2026-07-12 v0.5.9 crocs expansion

### Added / Updated

- crocsを4モデルから10モデルへ拡張
- 追加: `Classic Platform Clog` / `Classic Crush Clog` / `Mega Crush Clog` / `Mellow Recovery Clog` / `Dylan Clog` / `LiteRide 360 Clog`
- モデル固有のAliasと、ブランド名を含む日本語searchKeywordsを追加
- `data/*.json` と `app/assets/data/*.json` をv0.5.9へ同期

### Audited

- モデルID重複、Alias/searchKeywords参照先、JSON構文、data/app assets一致を検証
- `Clog` / `Classic` / `Platform` / `Crush` / `Recovery` / `LiteRide` / `Crocs`単体は広すぎるため除外

### Remaining

- Search MVP実動作テスト
- Tier S〜Bの国内流通差分監査
- 次のTier Cブランド集中拡張

---

このファイルは、`data/` 配下の実データ資産の変更履歴を管理する。

---

## 2026-07-09 v0.5.7 sync helper audit

### Updated

- `data/staging_dr_martens_v0.5.5.json` を `0.5.7-merge-ready-audited` に更新
- `data/sync_dr_martens_v0.5.7.py` を公式の同期手順として staging 側に明記
- Dr.Martens 15モデル、Alias、searchKeywords の merge-ready 状態を再確認

### Audited

- `1460` / `1461` は定番モデルとして信頼情報で確認済み
- 15モデルのID、brandId、modelName、category、source、Alias、searchKeywords の整合性を確認
- `Docs` / `DMs` / `Boot` / `Shoe` / `Loafer` / `Sandal` / `Mule` / `Chelsea` / `Platform` / `Martens` / `Dr.Martens` / `Doc Martens` 単体は引き続き除外
- root JSON と app/assets/data はまだ v0.5.4 同期状態。本体JSONは1行圧縮のため、破損防止を優先し、実行環境で同期スクリプトを走らせる方針を維持

### Remaining

- `python3 data/sync_dr_martens_v0.5.7.py` の実行
- 実行後の `data/*.json` / `app/assets/data/*.json` SHA一致確認
- Search MVPテストケース実施
- 次ブランドの集中追加

---

## 2026-07-08 v0.5.6 expanded staging

### Updated

- `data/staging_dr_martens_v0.5.5.json` を `0.5.6-merge-ready` に更新
- Dr.Martens の高確度モデル候補を 2件 -> 15件 に拡張
  - `1460`
  - `1461`
  - `2976`
  - `Jadon`
  - `Sinclair`
  - `Adrian`
  - `Blaire`
  - `Gryphon`
  - `Jorge`
  - `Carlson`
  - `8053`
  - `3989`
  - `101`
  - `Church`
  - `Ramsey`
- Alias / searchKeywords 候補も同じ15モデルに合わせて拡張
- `data/README.md` を v0.5.6-staging 状態に更新
- `data/validation_rules.md` を v1.8 に更新
- `specs/MODEL_MASTER_COVERAGE.md` を v2.3 に更新
- `specs/KICKXKICK_TASK_BOARD.md` を v2.7 に更新

### Audited

- `brands.json` に `dr_martens` が Tier C brand-only として登録済みであることを確認
- 信頼できる公開情報で、`1460` が8ホールブーツ、`1461` が3ホールシューズとして扱われていることを確認
- `2976` / `Jadon` / `Sinclair` / `Adrian` / `Blaire` / `Gryphon` は現在の商品・販売系リファレンスで確認できるため高確度として維持
- `8053` / `3989` / `101` / `Church` / `Ramsey` / `Jorge` / `Carlson` は識別性が高い固有モデル名としてステージング維持。ただし本体JSON反映前に再監査する
- `Docs` / `DMs` / `Boot` / `Shoe` / `Loafer` / `Sandal` / `Mule` / `Chelsea` / `Platform` / `Martens` / `Dr.Martens` / `Doc Martens` 単体は広すぎるため、Alias / searchKeywords には追加しない
- 色名、商品説明文、商品画像、在庫情報、コラボ名は追加なし

### Not Added To Root JSON

- `models.json` / `aliases.json` / `search_keywords.json` 本体への反映は未実施
- 理由: 現在の本体JSONは1行圧縮形式で、全体を安全に再生成せずに追記すると既存データ破損のリスクがあるため
- 次回はJSON整形または同期スクリプトを先に入れてから、本体JSONと `app/assets/data/` 側へ同時反映する

### Remaining

- Dr.Martens 0.5.6 expanded merge-ready payload の本体JSON反映
- `app/assets/data/*.json` への同期
- JSON同期の自動化または整形済みJSONへの移行
- Search MVPテストケース実施
- Tier S / A / B のABC-MART差分監査
- Tier Cブランドのモデル追加継続

---

## 2026-07-07 v0.5.5 staging audit

### Updated

- `data/staging_dr_martens_v0.5.5.json` を `0.5.5-merge-ready` に更新
- Dr.Martens の高確度モデル候補を本体JSON反映前の検証済みデータとして整理
  - `1460`
  - `1461`
- Alias / searchKeywords 候補も検証済みとして整理
  - `DrMartens1460` / `DocMartens1460`
  - `DrMartens1461` / `DocMartens1461`
  - `ドクターマーチン1460` / `ドクターマーチン1461`

### Audited

- `brands.json` に `dr_martens` が Tier C brand-only として登録済みであることを確認
- 信頼できる公開情報で、`1460` が8ホールブーツ、`1461` が3ホールシューズとして扱われていることを確認
- `1460` / `1461` は数字だけでも識別性が高いため、searchKeywords 候補として維持
- `Docs` / `Boot` / `Shoe` / `Martens` / `Dr.Martens` / `Doc Martens` 単体は広すぎるため、Alias / searchKeywords には追加しない
- 色名、商品説明文、商品画像、在庫情報、コラボ名は追加なし

### Not Added To Root JSON

- `models.json` / `aliases.json` / `search_keywords.json` 本体への反映は未実施
- 理由: 現在の本体JSONは1行圧縮形式で、全体を安全に再生成せずに追記すると既存データ破損のリスクがあるため
- 次回はJSON整形または同期スクリプトを先に入れてから、本体JSONと `app/assets/data/` 側へ同時反映する

---

## 2026-07-05 v0.5.4 audit

### Audited

- `data/models.json` と `app/assets/data/models.json` の blob SHA が一致していることを確認
- `data/aliases.json` と `app/assets/data/aliases.json` の blob SHA が一致していることを確認
- `data/search_keywords.json` と `app/assets/data/search_keywords.json` の blob SHA が一致していることを確認
- `brands.json` に `dr_martens` が Tier C brand-only として登録済みであることを確認
- Dr.Martens の次回追加候補として、信頼できる公開情報で `1460` / `1461` を確認

---

## 2026-07-04 v0.5.4

### Added / Updated

- `data/models.json` を v0.5.4 に更新
  - crocs: `Classic Clog` / `Crocband Clog` / `Classic Bae Clog` / `Echo Clog` を追加
- `app/assets/data/models.json` を v0.5.4 に同期更新
- `data/aliases.json` を v0.5.4 に更新
  - crocs: `ClassicClog` / `CrocsClassicClog` / `CrocbandClog` / `ClassicBaeClog` / `EchoClog` を追加
- `app/assets/data/aliases.json` を v0.5.4 に同期更新
- `data/search_keywords.json` を v0.5.4 に更新
  - crocs: `ClassicClog` / `クラシッククロッグ` / `CrocbandClog` / `クロックバンドクロッグ` / `ClassicBaeClog` / `クラシックベイクロッグ` / `EchoClog` / `エコークロッグ` を追加
- `app/assets/data/search_keywords.json` を v0.5.4 に同期更新

### Audited

- crocsは `brands.json` に既存登録済み
- クロックス日本公式ページで `クラシック クロッグ` / `クラシック ベイ クロッグ` / `エコー` / `クロックバンド` の掲載・導線を確認
- `Classic` / `Clog` / `Bae` / `Echo` など広すぎる単語単体はAlias/searchKeywordsに追加なし

---

## 2026-07-03 v0.5.3

### Added / Updated

- SKECHERS: `BOBS` / `Court & Classics` / `SKECHERS Street` / `GO GOLF` を追加
- SKECHERS累計: `D'Lites` / `Uno` / `GO WALK` / `GO RUN` / `BOBS` / `Court & Classics` / `SKECHERS Street` / `GO GOLF`
- data/models・aliases・search_keywords と app/assets/data 側を v0.5.3 として同期

### Audited

- SKECHERS公式サイトのCollectionsに追加モデルが掲載されていることを確認
- `BOBS` / `Court` / `Street` / `Golf` など広すぎる単語単体はAlias/searchKeywordsに追加なし

---

## 2026-07-02 v0.5.2

### Added / Updated

- SKECHERS: `D'Lites` / `Uno` / `GO WALK` / `GO RUN` を追加
- data/models・aliases・search_keywords と app/assets/data 側を同期

---

## 2026-07-01 v0.5.1 completion

### Added / Updated

- MERRELL / BROOKS の searchKeywords を追加
- `app/assets/data/aliases.json` / `app/assets/data/search_keywords.json` を同期
- `data/README.md`、`validation_rules.md`、Coverage、Task Board を更新

---

## 2026-06-30 v0.5.1

### Added

- MERRELL: `AGILITY PEAK 6` / `AGILITY PEAK 6 GORE-TEX` / `VAPOR GLOVE 7` / `TRAIL GLOVE 8` / `JUNGLE TREK MOC`
- BROOKS: `Ghost 18` / `Ghost Trail` / `Glycerin` / `Adrenaline` / `Hyperion` / `Cascadia Elite` / `Revel MAX` / `Vanguard`
- `data/models.json` / `data/aliases.json` / `app/assets/data/models.json` を更新

---

## 2026-06-29 v0.5.0

### Added

- `data/brands.json` を v0.5.0 に更新
  - ABC-MART掲載ブランドを基準に、ブランド名を先行追加
  - ブランド登録数を 12件 -> 90件 に拡張
  - `MERRELL` / `BROOKS` を Tier B brand-only として追加
  - その他の国内流通ブランドを Tier C brand-only として追加
- `app/assets/data/brands.json` を v0.5.0 に同期更新
- `data/MARKET_REFERENCE_POLICY.md` を更新
- `specs/MODEL_MASTER_COVERAGE.md` を v1.7 に更新

---

## 2026-06-29 v0.4.1

### Added

- `data/MARKET_REFERENCE_POLICY.md` を追加

---

## 2026-06-29 v0.4.0

### Added

- Tier Bとして `Saucony` / `SALOMON` を追加
- Saucony / SALOMON の代表モデル、Alias、searchKeywordsを追加
- `app/assets/data/*.json` を同期更新

---

## 2026-06-28 v0.3.1

### Added

- HOKA Alias / searchKeywords を追加
- `app/assets/data/aliases.json` / `app/assets/data/search_keywords.json` を同期更新

## 0.5.7 - 2026-07-10

- Merged 15 audited Dr.Martens models into root and app asset masters.
- Added model-specific aliases and Japanese/connected search keywords.
- Verified duplicate keys, referential integrity, JSON parsing, and root/app byte equality.


## v0.5.8 - 2026-07-11

- Expanded SKECHERS from 8 to 16 audited model families.
- Added Arch Fit, Max Cushioning, Hands Free Slip-ins, Glide-Step, Summits, Ultra Flex, Equalizer and Reggae.
- Synchronized data JSON with app assets and retained broad-term exclusions.
