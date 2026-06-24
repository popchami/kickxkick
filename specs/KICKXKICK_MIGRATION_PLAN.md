# Kick×Kick Migration Plan v1.0

## 1. 目的

この計画書は、旧 SoleMuseum 仕様から Kick×Kick 仕様へ移行するための整理方針を定義する。

現在のリポジトリには、旧SoleMuseum時代の資料・コード・命名が残っている。

Sprint1実装前に、AIが旧仕様を参照して混乱しないようにする。

## 2. 現在の問題

リポジトリ名と一部ファイルは `solemuseum` のまま。

ただし、プロダクト仕様は `Kick×Kick` に確定している。

混在しているもの:

- 旧SoleMuseum仕様書
- 旧SoleMuseum README
- 旧SoleMuseum docs
- 旧SoleMuseum app package name
- 旧SoleMuseum UI/文言

## 3. 移行方針

### 原則

- 旧SoleMuseum資料はすぐ削除しない
- 旧資料は archive に退避する
- 実装時に参照する仕様は `specs/KICKXKICK_*` に統一する
- READMEはKick×Kick基準へ更新する
- アプリコードのリネームはSprint1開始時に行う

## 4. 参照すべき新仕様

今後の正本は以下。

```text
specs/KICKXKICK_SPEC.md
specs/KICKXKICK_PRODUCT.md
specs/KICKXKICK_UI_SPEC.md
specs/KICKXKICK_DATA.md
specs/KICKXKICK_DB_SPEC.md
specs/KICKXKICK_ROUTING_SPEC.md
specs/KICKXKICK_MONETIZE.md
specs/KICKXKICK_BRAND.md
specs/KICKXKICK_BACKUP.md
specs/KICKXKICK_DESIGN_SYSTEM.md
specs/KICKXKICK_ICON_SPEC.md
specs/KICKXKICK_SCREENSHOT_SPEC.md
specs/KICKXKICK_TASK_BOARD.md
specs/KICKXKICK_SPRINT_PLAN.md
specs/KICKXKICK_SPRINT1_INSTRUCTION.md
specs/KICKXKICK_SPRINT2_INSTRUCTION.md
specs/KICKXKICK_SPRINT3_INSTRUCTION.md
specs/KICKXKICK_SPRINT4_INSTRUCTION.md
```

## 5. Archive対象候補

### docs配下

旧SoleMuseum資料として扱う候補:

```text
docs/APP_STORE_DESCRIPTION.md
docs/ARCHITECTURE.md
docs/BRAND_GUIDELINES.md
docs/CHANGELOG.md
docs/CONTRIBUTING.md
docs/DESIGN_SYSTEM.md
docs/DEVELOPMENT_WORKFLOW.md
docs/ISSUES.md
docs/README.md
docs/RELEASE_PLAN.md
docs/ROADMAP.md
docs/RUNTIME_VERIFICATION_CHECKLIST.md
docs/RUNTIME_VERIFICATION_PLAN.md
docs/SPRINT3_SPEC.md
docs/SPRINT6_SPEC.md
docs/USER_STORIES.md
```

### specs配下

旧SoleMuseum仕様として扱う候補:

```text
specs/COLLECTION_SCREEN_SPEC.md
specs/DATABASE_SPEC.md
specs/DESIGN_IMPROVEMENT_SPEC.md
specs/HOME_SCREEN_SPEC.md
specs/IMPLEMENTATION_RULES.md
specs/MVP_SPEC.md
specs/NAVIGATION_SPEC.md
specs/PHOTO_BACKGROUND_SPEC.md
specs/PROJECT_STRUCTURE_SPEC.md
specs/RELEASE_CHECKLIST.md
specs/SETTINGS_SCREEN_SPEC.md
specs/SHOE_DETAIL_SCREEN_SPEC.md
specs/SHOE_FORM_SCREEN_SPEC.md
specs/STATE_MANAGEMENT_SPEC.md
specs/UI_COMPONENT_SPEC.md
```

## 6. すぐに変更するもの

### README

READMEをKick×Kick基準に更新する。

記載内容:

- Kick×Kick
- 貼って、飾って、コレクション。
- Collect / Create / Exhibit
- 仕様書一覧
- Sprint1開始案内

### specs/README.md

Kick×Kick仕様書一覧へ更新する。

## 7. Sprint1で変更するもの

アプリコード側のリネームはSprint1実装時に行う。

候補:

- アプリ表示名
- package / namespace
- main.dart内タイトル
- Home文言
- Settings文言
- pubspec name

ただし、Android package name変更は影響が大きいため、実装担当AIに確認させる。

## 8. Archive方針

旧資料は以下へ移動する方針。

```text
archive/solemuseum/docs/
archive/solemuseum/specs/
```

GitHub上では削除ではなく移動扱いにする。

ただし、GitHub Contents APIでは移動が直接できない場合があるため、実作業では以下のいずれかを選ぶ。

1. 新しいarchiveファイルを作成して旧ファイルを削除
2. 旧ファイル先頭に `Archived: SoleMuseum legacy` を追記
3. 旧ファイルは残し、READMEで参照禁止を明記

スマホ運用ではまず 3 を推奨する。

## 9. 実装AIへの注意

Codex / Copilotへ渡す指示:

```text
旧SoleMuseum仕様は参照しないでください。
Kick×Kickの正本は specs/KICKXKICK_* です。
SoleMuseum名が残っている場合は、Kick×Kick仕様に従って置き換えてください。
```

## 10. 完了条件

移行整理の完了条件:

- READMEがKick×Kickになっている
- specs/README.mdがKick×Kick仕様一覧になっている
- 旧SoleMuseum資料が参照禁止であることが明確
- Sprint1実装指示でKick×Kick仕様のみ参照する状態になっている

## 11. 最重要ルール

今後の正本は `specs/KICKXKICK_*` のみ。

旧SoleMuseum資料は履歴として残すが、実装判断には使わない。