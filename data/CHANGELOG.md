# Kick×Kick Data Changelog

このファイルは、`data/` 配下の実データ資産の変更履歴を管理する。

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
- `data/README.md` を v0.5.4 状態に更新
- `data/validation_rules.md` を v1.6 に更新
- `specs/MODEL_MASTER_COVERAGE.md` を v2.1 に更新
- `specs/KICKXKICK_TASK_BOARD.md` を v2.5 に更新

### Audited

- crocsは `brands.json` に既存登録済み
- クロックス日本公式ページで `クラシック クロッグ` / `クラシック ベイ クロッグ` / `エコー` / `クロックバンド` の掲載・導線を確認
- `models.json.brandId -> brands.json.brandId` の追加分参照を確認
- `aliases.json.modelId -> models.json.id` の追加分参照を確認
- `search_keywords.json.modelId -> models.json.id` の追加分参照を確認
- `Classic` / `Clog` / `Bae` / `Echo` など広すぎる単語単体はAlias/searchKeywordsに追加なし
- 色名、商品説明文、商品画像、在庫情報、コラボ名は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier S / A / B のABC-MART差分監査
- Tier Cブランドのモデル追加継続
- SKECHERS / crocs の国内流通差分監査継続

---

## 2026-07-03 v0.5.3

### Added / Updated

- SKECHERS: `BOBS` / `Court & Classics` / `SKECHERS Street` / `GO GOLF` を追加
- SKECHERS累計: `D'Lites` / `Uno` / `GO WALK` / `GO RUN` / `BOBS` / `Court & Classics` / `SKECHERS Street` / `GO GOLF`
- data/models・aliases・search_keywords と app/assets/data 側を v0.5.3 として同期
- `data/README.md`、`data/validation_rules.md`、`specs/MODEL_MASTER_COVERAGE.md`、`specs/KICKXKICK_TASK_BOARD.md` を更新

### Audited

- SKECHERS公式サイトのCollectionsに追加モデルが掲載されていることを確認
- `BOBS` / `Court` / `Street` / `Golf` など広すぎる単語単体はAlias/searchKeywordsに追加なし
- 色名、商品説明文、商品画像、在庫情報、コラボ名は追加なし

---

## 2026-07-02 v0.5.2

### Added / Updated

- SKECHERS: `D'Lites` / `Uno` / `GO WALK` / `GO RUN` を追加
- data/models・aliases・search_keywords と app/assets/data 側を v0.5.2 として同期

### Audited

- SKECHERS公式サイトのCollectionsに `D'Lites` / `GO WALK` / `GO RUN` / `UNOs` が掲載されていることを確認
- `Uno` / `Walk` / `Run` など広すぎる単語単体はAlias/searchKeywordsに追加なし

---

## 2026-07-01 v0.5.1 completion

### Added / Updated

- MERRELL / BROOKS の searchKeywords を追加
- `app/assets/data/aliases.json` / `app/assets/data/search_keywords.json` を同期
- `data/README.md`、`validation_rules.md`、Coverage、Task Board を更新

### Audited

- `data/*.json` と `app/assets/data/*.json` の同期状態を回復
- `Peak` / `Glove` / `Ghost` / `Trail` / `Max` など広すぎる単語単体は追加なし
- 商品説明文、商品画像、在庫情報、色名、コラボ名は追加なし

---

## 2026-06-30 v0.5.1

### Added

- MERRELL: `AGILITY PEAK 6` / `AGILITY PEAK 6 GORE-TEX` / `VAPOR GLOVE 7` / `TRAIL GLOVE 8` / `JUNGLE TREK MOC`
- BROOKS: `Ghost 18` / `Ghost Trail` / `Glycerin` / `Adrenaline` / `Hyperion` / `Cascadia Elite` / `Revel MAX` / `Vanguard`
- `data/models.json` / `data/aliases.json` / `app/assets/data/models.json` を更新

### Audited

- MERRELL / BROOKS 公式情報で追加モデルを確認
- `Peak` / `Glove` / `Ghost` / `Trail` / `Max` など広すぎるAlias単体は追加なし

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

### Audited

- ABC-MARTブランド一覧に掲載されているブランド名を基準に追加
- 商品説明文、商品画像、在庫情報は追加なし
- 低確度モデルや広すぎるAlias/searchKeywordsは追加なし

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
