# Kick×Kick Codex Start Guide v1.0

このファイルは、Codex / GitHub Copilot / ChatGPT などのAI開発エージェントが、Kick×Kickの作業を安全に再開するための入口です。

---

## Project

```text
Kick×Kick
```

タグライン:

```text
貼って、飾って、コレクション。
```

コンセプト:

```text
スニーカーを登録し、ステッカー化し、棚やボードに飾って楽しむコレクションアプリ。
```

重要:

```text
売買・相場・資産管理アプリではない。
スニーカーを「貼る」「飾る」「コレクションする」体験を作る。
```

---

## First Files to Read

Codexは、作業前に必ず以下を読むこと。

```text
README.md
specs/KICKXKICK_TASK_BOARD.md
docs/HANDOFF_BRAND_MODEL_SEARCH.md
docs/KICKXKICK_RELEASE_PRIORITY.md
specs/KICKXKICK_DATA.md
specs/KICKXKICK_DB_SPEC.md
specs/SEARCH_SPEC.md
specs/REGISTRATION_FLOW_SPEC.md
specs/REGISTRATION_VALIDATION_SPEC.md
```

必要に応じて読む:

```text
docs/ARCHITECTURE.md
docs/DESIGN_SYSTEM.md
docs/BRAND_GUIDELINES.md
specs/SEARCH_DATA_SPEC.md
specs/ALIAS_MASTER_SPEC.md
specs/SEARCH_MVP_TEST_SPEC.md
```

---

## Current Status

```text
ブランド・モデル・検索基盤はいったん終了。
検索・登録はMVPリリース可能ライン。
次はKick×Kick本体のMVP実装を進める。
```

現在の優先順位:

```text
1. 登録画面の実機確認
2. flutter analyze
3. 詳細画面確認
4. 写真登録・表示・削除
5. TOP5
6. 着用履歴
7. Collection
8. Sticker
9. Premium / Backup / Release
```

---

## Most Important Rule

```text
Factory is support.
Kick×Kick release is the goal.
```

ブランド・モデル・検索Factoryを目的化しない。

Kick×Kick本体のMVP完成を優先する。

---

## Development Policy

### Do

```text
- 既存仕様を読む
- 既存コードを確認してから変更する
- MVPに必要な最小変更を行う
- 変更後に何を変えたか報告する
- 不明点は推測で決めず、仕様書に従う
- 仕様と実装が違う場合は、まず差分を報告する
```

### Do Not

```text
- アプリ名をSoleMuseumに戻さない
- Factory作業を勝手に再開しない
- ブランド・モデルを無制限に増やす作業へ戻らない
- ユーザー自由入力をマスターJSONへ自動追加しない
- ロゴ画像や商標素材を使わない
- 大規模リファクタを勝手に行わない
- 仕様未確定の機能を推測で実装しない
```

---

## Brand / Model / Search Policy

ブランド・モデル・検索はMVPでは以下で固定。

```text
- ブランド候補を表示する
- モデル候補を表示する
- Alias検索する
- searchKeywords検索する
- 数字検索する
- 候補にない場合は自由入力できる
- 自由入力ブランドは保存時にローカルDBへ追加する
- 自由入力モデルは靴1件のmodelNameとして保存する
- 自由入力はマスターJSONへ自動追加しない
- 誤入力は靴詳細→編集で修正する
```

関連:

```text
docs/HANDOFF_BRAND_MODEL_SEARCH.md
```

---

## Tech Stack

```text
Flutter
Dart
Material3
Riverpod
sqflite
local-first
```

サーバー前提にしない。

MVPではローカルファーストで進める。

---

## App Directory

Flutterアプリ本体:

```text
app/
```

主な実装場所:

```text
app/lib/main.dart
app/lib/screens/
app/lib/models/
app/lib/repositories/
app/lib/providers/
app/lib/features/search/
app/assets/data/
```

---

## Implemented Search Files

```text
app/lib/features/search/search.dart
app/lib/features/search/search_models.dart
app/lib/features/search/search_normalizer.dart
app/lib/features/search/search_index.dart
app/lib/features/search/search_service.dart
app/lib/features/search/search_repository.dart
app/lib/features/search/search_providers.dart
app/lib/features/search/widgets/brand_search_field.dart
app/lib/features/search/widgets/model_search_field.dart
app/lib/features/search/widgets/sneaker_master_picker.dart
app/lib/features/search/screens/search_demo_screen.dart
```

検索デモ入口:

```text
設定
↓
開発
↓
検索デモ
```

---

## Current Known Runtime Checks Needed

まだ実機・analyzeで確認が必要。

```text
- flutter pub get
- flutter analyze
- Flutter起動確認
- 登録画面が開くか
- ブランド候補が出るか
- モデル候補が出るか
- 自由入力ブランドが保存されるか
- 自由入力モデルが保存されるか
- 編集画面で修正できるか
- 写真登録が動くか
```

---

## Recommended First Codex Task

Codexに最初に依頼するなら、以下が安全。

```text
このリポジトリの docs/CODEX_START.md を読み、Kick×Kickの現在地を把握してください。
その後、app/ を対象に flutter analyze 相当で問題になりそうな箇所を静的に確認し、修正が必要なファイルと理由を報告してください。
勝手に大規模リファクタはしないでください。
```

次に依頼するなら:

```text
登録画面 ShoeFormScreen と search widgets の接続を確認し、自由入力ブランド・自由入力モデルが保存できる設計になっているかレビューしてください。
必要な最小修正だけ行ってください。
```

---

## Handoff Summary for Codex

```text
Kick×Kickは、スニーカーを貼って飾るコレクションアプリ。
ブランド・モデル・検索作業はいったん終了。
検索はMVPリリース可能ライン。
次はKick×Kick本体MVPを進める。
優先は登録画面の実機確認、flutter analyze、詳細画面、写真、TOP5、着用履歴、Collection、Sticker。
Factoryは支援であり、目的ではない。
```
