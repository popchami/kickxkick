# Kick×Kick Specs

## 概要

このディレクトリは、Kick×Kick の仕様書を管理する。

Kick×Kick は、スニーカーを登録し、ステッカー化し、棚やボードに飾って楽しむアプリである。

タグライン:

```text
貼って、飾って、コレクション。
```

---

## 正本ルール

今後の実装判断では、以下のファイルを正本とする。

```text
KICKXKICK_*
BRAND_MASTER.md
MODEL_MASTER/*
SEARCH_SPEC.md
SEARCH_DATA_SPEC.md
ALIAS_MASTER_SPEC.md
REGISTRATION_FLOW_SPEC.md
SEARCH_MVP_TEST_SPEC.md
```

旧SoleMuseum仕様書が残っていても、実装判断には使わない。

---

## 基本方針

- Flutter / Dart
- Material 3
- Riverpod
- Offline First
- Local DB First
- Collection = 博物館 / 整列展示
- Sticker = スクラップブック / 自由配置
- ブランド・モデル候補は入力補助であり、自由入力 fallback を必ず維持する

---

## Kick×Kick 仕様書一覧

### Core

```text
KICKXKICK_SPEC.md
KICKXKICK_PRODUCT.md
KICKXKICK_UI_SPEC.md
KICKXKICK_DATA.md
KICKXKICK_DB_SPEC.md
KICKXKICK_ROUTING_SPEC.md
```

### Search / Registration

```text
SEARCH_SPEC.md
SEARCH_DATA_SPEC.md
ALIAS_MASTER_SPEC.md
REGISTRATION_FLOW_SPEC.md
SEARCH_MVP_TEST_SPEC.md
```

役割:

```text
SEARCH_SPEC.md
- 検索挙動
- 一致ルール
- 並び順
- No Result時の挙動

SEARCH_DATA_SPEC.md
- 検索用データ構造
- Brand / Model / Alias Object
- priority / source / category

ALIAS_MASTER_SPEC.md
- Alias管理ルール
- 略称・日本語・数字検索
- Alias衝突時の扱い

REGISTRATION_FLOW_SPEC.md
- 登録フロー
- ブランド選択
- モデル選択
- 自由入力fallback
- 保存データ

SEARCH_MVP_TEST_SPEC.md
- MVP検索テストケース
- Alias検索確認
- 日本語検索確認
- 自由入力fallback確認
```

### Brand / Model Master

```text
BRAND_MASTER.md
MODEL_MASTER/README.md
MODEL_MASTER/*.md
```

役割:

```text
BRAND_MASTER.md
- ブランド一覧
- Tier
- Plannedブランド

MODEL_MASTER/README.md
- モデルマスター運用ルール

MODEL_MASTER/*.md
- ブランド別モデル候補
- Alias Candidates
```

### Monetize / Backup

```text
KICKXKICK_MONETIZE.md
KICKXKICK_BACKUP.md
```

### Brand / Design

```text
KICKXKICK_BRAND.md
KICKXKICK_DESIGN_SYSTEM.md
KICKXKICK_ICON_SPEC.md
KICKXKICK_SCREENSHOT_SPEC.md
```

### Sprint

```text
KICKXKICK_SPRINT_PLAN.md
KICKXKICK_SPRINT1_INSTRUCTION.md
KICKXKICK_SPRINT2_INSTRUCTION.md
KICKXKICK_SPRINT3_INSTRUCTION.md
KICKXKICK_SPRINT4_INSTRUCTION.md
```

### Management

```text
KICKXKICK_TASK_BOARD.md
KICKXKICK_MIGRATION_PLAN.md
../docs/AUDIT_TRACKER.md
```

---

## ユーザー満足度基準

Kick×Kickでは、以下を満たすことを重視する。

```text
1. 主要ブランドが候補に出る
2. 代表モデルが候補に出る
3. 略称・日本語・数字検索で見つかる
4. 候補がなくても自由入力で登録できる
5. 登録後に編集できる
```

候補の完全網羅より、ユーザーが登録を完了できることを優先する。

---

## 次に使うファイル

検索・登録機能の実装時は以下を使う。

```text
SEARCH_SPEC.md
SEARCH_DATA_SPEC.md
ALIAS_MASTER_SPEC.md
REGISTRATION_FLOW_SPEC.md
SEARCH_MVP_TEST_SPEC.md
```

Sprint1実装開始時は以下を使う。

```text
KICKXKICK_SPRINT1_INSTRUCTION.md
```

---

## Legacy Notice

以下のような旧仕様書は、SoleMuseum時代の履歴として残っている場合がある。

```text
MVP_SPEC.md
HOME_SCREEN_SPEC.md
COLLECTION_SCREEN_SPEC.md
SHOE_FORM_SCREEN_SPEC.md
SHOE_DETAIL_SCREEN_SPEC.md
DATABASE_SPEC.md
NAVIGATION_SPEC.md
UI_COMPONENT_SPEC.md
```

これらは参考履歴であり、Kick×Kick実装の正本ではない。
