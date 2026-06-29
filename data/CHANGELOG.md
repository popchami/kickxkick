# Kick×Kick Data Changelog

このファイルは、`data/` 配下の実データ資産の変更履歴を管理する。

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

- `data/README.md` / `data/validation_rules.md` の詳細追記
- `specs/KICKXKICK_TASK_BOARD.md` の進捗反映
- MERRELL / BROOKS のモデル追加
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
