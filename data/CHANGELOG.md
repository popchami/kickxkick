# Kick×Kick Data Changelog

このファイルは、`data/` 配下の実データ資産の変更履歴を管理する。

---

## 2026-07-02 v0.5.2

### Added / Updated

- `data/models.json` を v0.5.2 に更新
  - SKECHERS: `D'Lites` / `Uno` / `GO WALK` / `GO RUN`
- `app/assets/data/models.json` を v0.5.2 に同期更新
- `data/aliases.json` を v0.5.2 に更新
  - SKECHERS: `DLites` / `D-Lites` / `SkechersUno` / `GoWalk` / `GoRun`
- `app/assets/data/aliases.json` を v0.5.2 に同期更新
- `data/search_keywords.json` を v0.5.2 に更新
  - SKECHERS: `DLites` / `ディーライツ` / `SkechersUno` / `スケッチャーズウノ` / `GoWalk` / `ゴーウォーク` / `GoRun` / `ゴーラン`
- `app/assets/data/search_keywords.json` を v0.5.2 に同期更新
- `data/README.md` を v0.5.2 状態に更新
- `data/validation_rules.md` を v1.4 に更新
- `specs/MODEL_MASTER_COVERAGE.md` を v1.9 に更新
- `specs/KICKXKICK_TASK_BOARD.md` を v2.3 に更新

### Audited

- SKECHERS公式サイトのCollectionsに `D'Lites` / `GO WALK` / `GO RUN` / `UNOs` が掲載されていることを確認
- `skechers` は `brands.json` に既存登録済み
- `models.json.brandId -> brands.json.brandId` の参照を確認
- `aliases.json.modelId -> models.json.id` の追加分参照を確認
- `search_keywords.json.modelId -> models.json.id` の追加分参照を確認
- `Uno` / `Walk` / `Run` など広すぎる単語単体はAlias/searchKeywordsに追加なし
- 色名、商品説明文、商品画像、在庫情報、コラボ名は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier S / A / B のABC-MART差分監査
- Tier Cブランドのモデル追加継続

---

## 2026-07-01 v0.5.1 completion

### Added / Updated

- `app/assets/data/aliases.json` を v0.5.1 に同期更新
- `data/search_keywords.json` を v0.5.1 に更新
  - MERRELL: `AgilityPeak6` / `アジリティピーク6` / `AgilityPeak6GTX` / `AgilityPeak6GORETEX` / `アジリティピーク6ゴアテックス` / `VaporGlove7` / `ベイパーグローブ7` / `TrailGlove8` / `トレイルグローブ8` / `JungleTrekMoc` / `ジャングルトレックモック`
  - BROOKS: `Ghost18` / `ゴースト18` / `GhostTrail` / `ゴーストトレイル` / `グリセリン` / `アドレナリン` / `AdrenalineGTS` / `ハイペリオン` / `CascadiaElite` / `カスケディアエリート` / `RevelMax` / `レベルマックス` / `ヴァンガード`
- `app/assets/data/search_keywords.json` を v0.5.1 に同期更新
- `data/README.md` を v0.5.1 状態に更新
- `data/validation_rules.md` を v1.3 に更新
- `specs/MODEL_MASTER_COVERAGE.md` を v1.8 に更新
- `specs/KICKXKICK_TASK_BOARD.md` を v2.2 に更新

### Audited

- `data/*.json` と `app/assets/data/*.json` の同期状態を回復
- MERRELL / BROOKS の `models -> aliases -> search_keywords` の整合性を更新
- `Peak` / `Glove` / `Ghost` / `Trail` / `Max` など広すぎる単語単体は追加なし
- `7` / `8` / `18` など単体数字検索は追加なし
- 商品説明文、商品画像、在庫情報、色名、コラボ名は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier S / A / B のABC-MART差分監査
- Tier Cブランドのモデル追加

---

## 2026-06-30 v0.5.1

### Added

- `data/models.json` を v0.5.1 に更新
  - MERRELL: `AGILITY PEAK 6` / `AGILITY PEAK 6 GORE-TEX` / `VAPOR GLOVE 7` / `TRAIL GLOVE 8` / `JUNGLE TREK MOC`
  - BROOKS: `Ghost 18` / `Ghost Trail` / `Glycerin` / `Adrenaline` / `Hyperion` / `Cascadia Elite` / `Revel MAX` / `Vanguard`

- `app/assets/data/models.json` を v0.5.1 に同期更新

- `data/aliases.json` を v0.5.1 に更新
  - MERRELL / BROOKS の連結表記Aliasを追加
  - 広すぎる単語単体は追加なし

### Audited

- MERRELL公式オンラインストア上で `AGILITY PEAK 6` / `AGILITY PEAK 6 GORE-TEX` / `VAPOR GLOVE 7` / `TRAIL GLOVE 8` / `JUNGLE TREK MOC` の掲載を確認
- BROOKS公式オンラインショップ上で `Ghost` / `Glycerin` / `Adrenaline` / `Hyperion` 系列、および `Ghost 18` / `Ghost Trail` / `Cascadia Elite` / `Revel MAX` / `Vanguard` の掲載を確認
- `models.json.brandId -> brands.json.brandId` は `merrell` / `brooks` とも既存登録済みブランドを参照
- 色名、商品説明文、商品画像、在庫情報は追加なし
- `Peak` / `Glove` / `Ghost` / `Trail` / `Max` など広すぎるAlias単体は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier S / A / B のABC-MART差分監査
- Tier Cブランドのモデル追加

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
  - まずブランド名を国内流通リファレンスに近づける方針を明記
  - モデル・Alias・searchKeywordsはブランドごとに段階追加する方針を明記
  - 代表モデルだけで止めず、国内流通リファレンスの掲載量に近づける方針を明記

- `specs/MODEL_MASTER_COVERAGE.md` を v1.7 に更新
  - BRAND_ONLY ステータスを追加
  - Tier Bに `MERRELL` / `BROOKS` を brand-only で追加
  - Tier C Brand Registry を追加

### Audited

- ABC-MARTブランド一覧に掲載されているブランド名を基準に追加
- 今回はブランド名のみ追加し、models / aliases / search_keywords は変更なし
- `models.json.brandId -> brands.json.brandId` の参照は既存モデル分を維持
- 商品説明文、商品画像、在庫情報は追加なし
- 低確度モデルや広すぎるAlias/searchKeywordsは追加なし

### Remaining

- Tier Cブランドのモデル追加
- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化

---

## 2026-06-29 v0.4.1

### Added

- `data/MARKET_REFERENCE_POLICY.md` を追加
  - 国内大手販売サイトを、完成形に近い国内流通リファレンスとして扱う方針を明文化
  - Tier S / Tier A も完成固定ではなく、差分監査を継続する方針を明記
  - 新作モデルが増えた場合、Kick×Kickでも追加候補として扱う運用を明記

### Audited

- この時点ではデータJSON本体の追加・変更はなし
- 商品説明文・画像・在庫情報をコピーしない方針を維持

---

## 2026-06-29 v0.4.0

### Added

- `data/brands.json` を v0.4.0 に更新
  - Tier Bとして `Saucony` / `SALOMON` を追加

- `data/models.json` を v0.4.0 に更新
  - Saucony: `Ride 19` / `Triumph 24` / `Guide 19` / `Hurricane 25` / `ProGrid Omni 9` / `ProGrid Guide 7`
  - SALOMON: `XT-6` / `XT-WHISPER` / `XA PRO` / `SPEEDCROSS` / `X ULTRA` / `XT-4`

- `data/aliases.json` / `data/search_keywords.json` を v0.4.0 に更新
  - Saucony / SALOMON のAlias・日本語検索・連結表記を追加

- `app/assets/data/*.json` を v0.4.0 として同期更新

### Audited

- ABC-MARTブランド一覧に `Saucony` / `SALOMON` が掲載されていることを確認
- 公式情報でモデル名を確認
- 低確度モデル、色名、コラボ名は追加なし

---

## 2026-06-28 v0.3.1

### Added

- HOKA Alias / searchKeywords を追加
- `app/assets/data/aliases.json` / `app/assets/data/search_keywords.json` を同期更新

### Audited

- HOKAの既存6モデルに対する検索補助のみ追加
- 低確度モデル、色名、コラボ名は追加なし

---
