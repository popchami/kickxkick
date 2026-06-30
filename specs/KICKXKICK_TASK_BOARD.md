# Kick×Kick Task Board v2.2

## 目的

Kick×Kick開発の現在地を管理する。

スマホのみ開発でも、次に何をやるべきか迷わない状態を維持する。

---

# Current Status

```text
ブランド・モデル・検索基盤はMVPリリース可能ライン。
Tier S / Tier A はPASS。
Tier BはHOKA / Saucony / SALOMON / MERRELL / BROOKSを追加し、Alias / searchKeywords までPASS化済み。
Tier Cはブランド名のみ先行登録済み。
ABC-MARTなど国内流通リファレンスを基準に、今後もデータ資産を継続育成する。
data/*.json と app/assets/data/*.json は v0.5.1 として同期済み。
次はSearch MVPテスト、TOP5・着用履歴・詳細確認を進める。
```

引き継ぎ:

```text
docs/HANDOFF_BRAND_MODEL_SEARCH.md
```

---

# Backlog

未着手

## Product

- [ ] 利用規約
- [ ] プライバシーポリシー
- [ ] ストア説明文
- [ ] ストアキーワード
- [ ] FAQ

## Design

- [ ] アプリアイコン作成
- [ ] Splash作成
- [ ] Homeモック
- [ ] Collectionモック
- [ ] Stickerモック

## Development

- [ ] Sprint1実装
- [ ] Sprint2実装
- [ ] Sprint3実装
- [ ] Sprint4実装

## Master Data / Search

状態:

```text
ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.5.1 SYNCED
```

- [x] BRAND_MASTER.md 作成
- [x] MODEL_MASTER 運用ルール作成
- [x] MODEL_MASTER_DATA_SPEC.md 作成
- [x] SEARCH_SPEC.md 作成
- [x] SEARCH_DATA_SPEC.md 作成
- [x] ALIAS_MASTER_SPEC.md 作成
- [x] ALIAS_MASTER.md 作成
- [x] REGISTRATION_FLOW_SPEC.md 作成
- [x] REGISTRATION_VALIDATION_SPEC.md 作成
- [x] SEARCH_MVP_TEST_SPEC.md 作成
- [x] data/brands.json 作成
- [x] data/models.json 作成
- [x] data/aliases.json 作成
- [x] data/search_keywords.json 作成
- [x] app/assets/data/*.json 登録
- [x] Search Engine 実装
- [x] Search Repository / Provider 実装
- [x] Brand / Model Search Widget 実装
- [x] Search Demo Screen 実装
- [x] ShoeFormScreen 接続
- [x] 自由入力ブランド保存
- [x] data validation script 作成
- [x] data quality GitHub Actions 作成
- [x] Tier S data JSON監査
- [x] Canonical Name監査
- [x] searchKeywords監査
- [x] Alias横断監査
- [x] data/*.json と app/assets/data/*.json の手動同期
- [x] Tier Aブランド追加
- [x] Tier Aモデル追加
- [x] Tier A searchKeywords追加
- [x] app/assets/data/aliases.json 同期確認
- [x] Tier Bブランド追加: HOKA
- [x] Tier Bモデル追加: HOKA 6件
- [x] HOKA Alias追加
- [x] HOKA searchKeywords追加
- [x] app/assets/data/aliases.json / search_keywords.json 同期更新
- [x] Tier Bブランド追加: Saucony / SALOMON
- [x] Tier Bモデル追加: Saucony 6件 / SALOMON 6件
- [x] Saucony / SALOMON Alias追加
- [x] Saucony / SALOMON searchKeywords追加
- [x] app/assets/data/*.json v0.4.0 同期更新
- [x] data/README.md Market Reference Policy 更新
- [x] data/validation_rules.md v1.2 更新
- [x] MODEL_MASTER_COVERAGE v1.6 更新
- [x] ABC-MART掲載ブランドを基準に brands.json を90ブランドへ拡張
- [x] MERRELL / BROOKS を Tier B brand-only 追加
- [x] Tier C ブランドを brand-only 先行登録
- [x] MERRELL / BROOKS モデル追加
- [x] MERRELL / BROOKS Alias追加
- [x] MERRELL / BROOKS searchKeywords追加
- [x] app/assets/data/aliases.json v0.5.1 同期
- [x] app/assets/data/search_keywords.json v0.5.1 同期
- [x] data/README.md v0.5.1反映
- [x] data/validation_rules.md v1.3反映
- [x] MODEL_MASTER_COVERAGE v1.8反映

保留:

- [ ] Search MVPテストケース実施
- [ ] data/*.json と app/assets/data/*.json の同期自動化
- [ ] Tier S / A / B のABC-MART差分監査
- [ ] Tier Cブランドのモデル追加

---

# Sprint1

状態:

```text
IN PROGRESS / RUNTIME CHECK STARTED
```

目的:

スニーカー登録・詳細・TOP5・着用履歴

## Sprint1 Tasks

### Foundation

- [x] Flutter起動確認
- [ ] flutter analyze
- [x] Material3確認
- [x] Riverpod確認
- [x] Bottom Navigation確認
- [x] FAB確認

### Sneaker

- [x] Sneaker Model確認
- [x] Sneaker Repository確認
- [x] Sneaker Provider確認
- [x] ShoeForm 実機確認
- [ ] Shoe Detail確認

### Search / Registration

状態:

```text
IMPLEMENTED / PHOTO SAVE CHECKED / DATA v0.5.1 SYNCED
```

- [x] Load app/assets/data/brands.json
- [x] Load app/assets/data/models.json
- [x] Load app/assets/data/aliases.json
- [x] Load app/assets/data/search_keywords.json
- [x] Brand search model
- [x] Model search model
- [x] Alias search model
- [x] Search normalization
- [x] Brand-first model suggestion
- [x] Alphabetical suggestion limit 5
- [x] Number search via searchKeywords
- [x] Canonical modelName save
- [x] Brand candidate UI
- [x] Model candidate UI
- [x] Brand change resets model
- [x] Free input fallback
- [x] Registration flow integration
- [x] Free input brand local save
- [ ] Search MVP test cases 実施
- [x] 実機で登録保存確認
- [ ] 編集画面で誤入力修正確認

参照仕様:

```text
SEARCH_SPEC.md
SEARCH_DATA_SPEC.md
ALIAS_MASTER_SPEC.md
ALIAS_MASTER.md
MODEL_MASTER_DATA_SPEC.md
REGISTRATION_FLOW_SPEC.md
REGISTRATION_VALIDATION_SPEC.md
SEARCH_MVP_TEST_SPEC.md
BRAND_MASTER.md
MODEL_MASTER/README.md
../data/brands.json
../data/models.json
../data/aliases.json
../data/search_keywords.json
../docs/KICKXKICK_RELEASE_PRIORITY.md
../docs/HANDOFF_BRAND_MODEL_SEARCH.md
```

### Photo

- [x] 写真登録
- [x] 写真表示
- [ ] 写真削除

### TOP5

- [ ] TOP5 Provider
- [ ] TOP5 UI
- [ ] TOP5登録
- [ ] TOP5入替

### Wear History

- [ ] 今日履いた
- [ ] 過去日追加
- [ ] 回数集計

### Home

- [ ] TOP5表示
- [ ] 最近追加したスニーカー
- [ ] Statistics簡易版

---

# Sprint2

状態:

```text
WAITING
```

目的:

Collection

## Sprint2 Tasks

- [ ] Collection Model
- [ ] Collection Repository
- [ ] Collection Provider
- [ ] Shelf List
- [ ] Shelf Create
- [ ] Shelf Delete
- [ ] Theme Select
- [ ] Slot Layout
- [ ] Zoom 2-5
- [ ] Box Display

---

# Sprint3

状態:

```text
WAITING
```

目的:

Sticker / Board

## Sprint3 Tasks

- [ ] Sticker Model
- [ ] Sticker Repository
- [ ] Sticker Board
- [ ] Sticker Search
- [ ] Sticker Edit Mode
- [ ] Cutout Flow
- [ ] Board Export

---

# Sprint4

状態:

```text
WAITING
```

目的:

Settings / Premium / Backup

## Sprint4 Tasks

- [ ] Theme unlock
- [ ] Premium gate
- [ ] Backup export
- [ ] Backup import
- [ ] App information
