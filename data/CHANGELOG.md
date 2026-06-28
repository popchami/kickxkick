# Kick×Kick Data Changelog

このファイルは、`data/` 配下の実データ資産の変更履歴を管理する。

Gitのcommit履歴とは別に、データとして何を追加・変更・修正したかを人間が追いやすくするために残す。

---

## 2026-06-29 v0.4.0

### Added

- `data/brands.json` を v0.4.0 に更新
  - Tier Bとして `Saucony` / `SALOMON` を追加

- `data/models.json` を v0.4.0 に更新
  - Saucony: `Ride 19` / `Triumph 24` / `Guide 19` / `Hurricane 25` / `ProGrid Omni 9` / `ProGrid Guide 7`
  - SALOMON: `XT-6` / `XT-WHISPER` / `XA PRO` / `SPEEDCROSS` / `X ULTRA` / `XT-4`

- `data/aliases.json` を v0.4.0 に更新
  - Saucony: `Ride19` / `Triumph24` / `Guide19` / `Hurricane25` / `ProGridOmni9` / `ProGridGuide7`
  - SALOMON: `XT6` / `XTWhisper` / `XAPro` / `Speedcross` / `XUltra` / `XT4`

- `data/search_keywords.json` を v0.4.0 に更新
  - Saucony / SALOMON の連結表記・日本語検索を追加

- `app/assets/data/*.json` を v0.4.0 として同期更新

- `data/README.md` を更新
  - ABC-MARTなど国内大手販売サイトをリファレンスとして扱う運用を明記

- `data/validation_rules.md` を v1.2 に更新
  - Market Reference Rule を追加
  - `Ride` / `Guide` / `XT` / `Pro` など広すぎる検索語をNG例に追加

### Audited

- ABC-MARTブランド一覧に `Saucony` / `SALOMON` が掲載されていることを確認
- Saucony公式サイト上で、追加モデルのうち `Ride 19` / `Triumph 24` / `Guide 19` / `Hurricane 25` / `ProGrid Omni 9` / `ProGrid Guide 7` を確認
- SALOMON公式サイト上で、定番モデルとして `XT-6` / `XT-WHISPER` / `XA PRO` / `SPEEDCROSS` / `X ULTRA` / `XT-4` を確認
- `models.json.brandId -> brands.json.brandId` の参照を確認
- `aliases.json.modelId -> models.json.id` の追加分参照を確認
- `search_keywords.json.modelId -> models.json.id` の追加分参照を確認
- `data/*.json` と `app/assets/data/*.json` の同期を確認
- 1文字数字検索 `4` / `6` / `7` / `9` は追加しない
- `Ride` / `Guide` / `XT` / `Pro` など広すぎる単語単体は追加しない
- 低確度モデル、色名、コラボ名は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier S/AのABC-MART差分監査を継続
- Tier B次候補: Mizuno / On / Merrell / Brooks などを国内流通・公式確認ベースで検討

---

## 2026-06-28 v0.3.1

### Added

- `data/aliases.json` を v0.3.1 に更新
  - HOKA: `Bondi9` / `Clifton10` / `Speedgoat7` / `Arahi8` / `Transport2` / `Challenger8`

- `data/search_keywords.json` を v0.3.1 に更新
  - HOKA: 連結表記と日本語検索を追加
  - `Bondi9` / `ボンダイ9`
  - `Clifton10` / `クリフトン10`
  - `Speedgoat7` / `スピードゴート7`
  - `Arahi8` / `アラヒ8`
  - `Transport2` / `トランスポート2`
  - `Challenger8` / `チャレンジャー8`

- `app/assets/data/aliases.json` / `app/assets/data/search_keywords.json` を同期更新

### Audited

- HOKAの既存6モデルに対する検索補助のみ追加
- 参照先 `modelId` は `data/models.json` に存在することを確認
- 1文字数字検索 `9` / `7` / `8` / `2` は追加しない
- `Bondi` / `Clifton` / `Speedgoat` など世代を含まない広いシリーズ名単体は追加しない
- 低確度モデル、色名、コラボ名は追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier B/Cの次候補追加は別作業で検討

---

## 2026-06-28 v0.3.0

### Added

- `data/brands.json` を v0.3.0 に更新
  - Tier Bとして `HOKA` を追加

- `data/models.json` を v0.3.0 に更新
  - HOKA: `Bondi 9` / `Clifton 10` / `Speedgoat 7` / `Arahi 8` / `Transport 2` / `Challenger 8`

- `app/assets/data/brands.json` / `app/assets/data/models.json` を同期更新

### Audited

- HOKA公式サイト上で確認できる高確度モデルのみ追加
- `Bondi 9` / `Clifton 10` / `Arahi 8` は公式商品一覧で確認
- `Speedgoat 7` / `Transport 2` / `Challenger 8` は公式商品一覧で確認
- `models.json.brandId -> brands.json.brandId` の参照を確認
- 低確度モデル、色名、コラボ名、広すぎるAlias/searchKeywordsは追加なし

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier B/Cの次候補追加

---

## 2026-06-26 v0.2.0

### Added

- `data/brands.json` を v0.2.0 に更新
  - Tier Aとして `PUMA` / `Converse` / `Vans` / `Reebok` を追加

- `data/models.json` を v0.2.0 に更新
  - PUMA: `Suede` / `Palermo` / `Speedcat` / `Clyde` / `RS-X` / `Basket`
  - Converse: `Chuck Taylor All Star` / `Chuck 70` / `One Star` / `Jack Purcell` / `Weapon` / `Run Star Hike`
  - Vans: `Old Skool` / `Authentic` / `Classic Slip-On` / `Sk8-Hi` / `Era` / `Knu Skool`
  - Reebok: `Club C` / `Classic Leather` / `Instapump Fury` / `Workout Plus` / `Freestyle` / `Question`

- `data/aliases.json` を v0.2.0 に更新
  - Tier Aモデルのスペースなし表記、定番略称を追加
  - 広すぎるAliasは追加なし

- `data/search_keywords.json` を v0.2.0 に更新
  - Tier Aモデルの日本語検索、連結表記を追加
  - 1文字検索語、広すぎる一般語は追加なし

- `app/assets/data/brands.json` / `app/assets/data/models.json` / `app/assets/data/search_keywords.json` を同期更新

### Audited

- `models.json.brandId -> brands.json.brandId` の参照を確認
- `aliases.json.modelId -> models.json.id` の参照を確認
- `search_keywords.json.modelId -> models.json.id` の参照を確認
- Tier Sは引き続きPASS維持
- Tier Aは高確度代表モデルのみ追加
- 低確度モデル、色名、コラボ名、広すぎる検索語は追加しない方針を維持

### Remaining

- Search MVPテストケース実施
- data/*.json と app/assets/data/*.json の同期自動化
- Tier B/Cは次回以降に段階追加

---

## 2026-06-26

### Added

- `data/aliases.json` を v0.1.1 に更新
  - Nike: `AirForce1` / `AirMax1` / `AirMax90` を追加
  - Air Jordan: `J2` / `Jordan2` / `J5` / `Jordan5` / `J11` / `Jordan11` などを追加
  - adidas: `ForumLow` / `ForumMid` / `Adimatic` を追加
  - New Balance: `NB990v1`〜`NB990v6` を追加
  - ASICS: `GelKayano14` を追加

- `data/search_keywords.json` を v0.1.2 に更新
  - Air Jordan: `Jordan2`〜`Jordan14`、`ジョーダン2`〜`ジョーダン14` の主要検索を補強
  - adidas: `ForumLow` / `ForumMid` / `フォーラムロー` / `フォーラムミッド` / `アディマティック` / `ウルトラブースト` を追加
  - ASICS: `ゲル1130` / `ゲル1090` / `GelKayano14` / `ゲルNYC` / `ゲルニンバス9` / `ノヴァブラスト` / `スーパーブラスト` を追加

- `app/assets/data/aliases.json` と `app/assets/data/search_keywords.json` を同期更新

### Audited

- Tier Sの `models.json.brandId -> brands.json.brandId` 参照を確認
- `aliases.json.modelId -> models.json.id` の追加分参照を確認
- `search_keywords.json.modelId -> models.json.id` の追加分参照を確認
- 1文字だけの数字・英字、`Air` / `Max` / `GEL` などの広すぎる検索語は追加しない方針を維持
- 低確度モデル追加は実施せず、既存Tier Sモデルの検索補助のみ補強

### Changed

- `specs/MODEL_MASTER_COVERAGE.md` のTier S監査状態を更新
- `specs/KICKXKICK_TASK_BOARD.md` のMaster Data / Search進捗を更新

### Notes

- 今回はTier A/B/Cブランド追加には進まず、Tier Sの検索品質を優先した
- 次回以降は、実機Search MVPテストと、Tier A候補の高確度ブランド追加を分けて進める

---

## 2026-06-25

### Added

- `data/brands.json` を追加
  - Tier S ブランドを初期登録
  - Nike
  - Air Jordan
  - adidas
  - New Balance
  - ASICS

- `data/models.json` を追加
  - Tier S ブランドのMVP向け代表モデルを登録

- `data/aliases.json` を追加
  - AF1 / AJ1 / AM95 / P6000 / GT2160 / NB550 などの検索Aliasを登録

- `data/search_keywords.json` を追加
  - 95 / 990 / 2160 / 1130 / AirMax95 / エアマックス95 などを登録

- `data/README.md` を追加
- `data/validation_rules.md` を追加
- `data/schema/` を追加

### Changed

- `specs/README.md` に `../data/*.json` を正本として追加
- `specs/KICKXKICK_TASK_BOARD.md` のCurrent Focusを `data JSON監査・Tier S補強` に変更

### Fixed

- データ運用方針を `specs/` 中心から `data/` 実データ資産中心へ移行

### Notes

- 2026-06-25時点では `data/*.json` は v0.1.0 として扱う
- 今後は `data/CHANGELOG.md` に実データ変更の意味を記録する