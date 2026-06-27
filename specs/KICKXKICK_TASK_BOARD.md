# Kick×Kick Task Board v1.8

## 目的

Kick×Kick開発の現在地を管理する。

スマホのみ開発でも、次に何をやるべきか迷わない状態を維持する。

---

# Current Status

```text
ブランド・モデル・検索基盤はいったん終了。
Tier S data JSON監査・検索補助の追加補強も完了。
Tier AとしてPUMA / Converse / Vans / Reebokを高確度で追加。
検索・登録はMVPリリース可能ライン。
実機で写真保存まで確認済み。
次はapp/assets/data/aliases.json同期、Search MVPテスト、TOP5・着用履歴・詳細確認を進める。
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
ACTIVE / TIER A PARTIAL
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
- [ ] app/assets/data/aliases.json 同期更新

保留:

- [ ] Search MVPテストケース実施
- [ ] data/*.json と app/assets/data/*.json の同期自動化
- [ ] Tier B/Cブランド追加

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
IMPLEMENTED / PHOTO SAVE CHECKED
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

Sticker

## Sprint3 Tasks

- [ ] Sticker Model
- [ ] Sticker Repository
- [ ] Sticker Provider
- [ ] Sticker Board
- [ ] Sticker Generate
- [ ] Background Remove
- [ ] Move
- [ ] Rotate
- [ ] Scale
- [ ] Duplicate
- [ ] Undo
- [ ] Redo

---

# Sprint4

状態:

```text
WAITING
```

目的:

Premium / Backup / Export

## Sprint4 Tasks

- [ ] Free制限
- [ ] Premium判定
- [ ] PNG出力
- [ ] ゴミ箱
- [ ] 復元
- [ ] Backup
- [ ] Restore
- [ ] .kkb対応

---

# Release Checklist

## Before Release

- [ ] flutter analyze
- [x] 実機確認
- [ ] クラッシュ確認
- [ ] アイコン完成
- [ ] スクリーンショット完成
- [ ] 利用規約
- [ ] プライバシーポリシー
- [ ] ストア文言
- [ ] Search MVPテスト通過
- [ ] 自由入力fallback確認
- [ ] ブランド変更時モデルリセット確認
- [ ] 正式modelName保存確認
- [x] app/assets/data JSON読み込み確認

---

# Runtime Check Log

```text
2026-06-27: 実機確認で写真保存まで確認済み。
```

確認済み:

```text
- アプリ起動
- 登録画面
- 登録保存
- 写真保存
```

未確認:

```text
- flutter analyze
- 編集画面で誤入力修正
- Shoe Detail全体確認
- TOP5登録/解除
- 着用履歴
- 写真削除
- Collection
- Sticker
```

---

# Data Check Log

```text
2026-06-26: Tier AとしてPUMA / Converse / Vans / Reebokを追加。
```

確認済み:

```text
- data/brands.json v0.2.0
- data/models.json v0.2.0
- data/aliases.json v0.2.0
- data/search_keywords.json v0.2.0
- app/assets/data/brands.json v0.2.0
- app/assets/data/models.json v0.2.0
- app/assets/data/search_keywords.json v0.2.0
```

未完了:

```text
- app/assets/data/aliases.json v0.2.0同期
```

---

# Current Focus

現在やること:

```text
app/assets/data/aliases.json同期 / Search MVPテスト / 写真保存後のMVP確認
```

次:

```text
詳細画面確認 / TOP5 / 着用履歴
```

その次:

```text
Collection / Sticker
```

最重要ルール:

```text
Factory is support.
Kick×Kick release is the goal.
```

ブランド・モデル・検索は一旦終了ではなく、MVPを壊さない範囲で段階育成する。

Collect.
Create.
Exhibit.

この体験を完成させる。
