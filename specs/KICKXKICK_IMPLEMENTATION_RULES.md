# Kick×Kick Implementation Rules v1.0

## 1. 目的

Kick×Kick の実装時に守る開発ルールを定義する。

Codex / Copilot / ChatGPT を使う場合も、この仕様を優先する。

## 2. 基本方針

最優先は、動くこと。

避けること:

- 過度な最適化
- 過度な抽象化
- 過度なClean Architecture化
- 仕様にない機能追加

## 3. 技術スタック

```text
Flutter
Dart
Material 3
Riverpod
SQLite
```

## 4. アーキテクチャ

基本構造:

```text
UI
↓
Provider
↓
Repository
↓
Database / Service
```

## 5. 実装優先順位

1. 画面が開く
2. データが保存される
3. 再起動後も残る
4. 写真が表示される
5. 操作が分かりやすい
6. デザインを整える

## 6. ファイル方針

- 画面は `screens/`
- 共通UIは `widgets/`
- 状態管理は `providers/`
- データモデルは `models/`
- DB操作は `repositories/` または `database/`
- ファイル保存や画像処理は `services/`

既存構成を大きく壊さない。

## 7. Riverpod方針

- Providerを使う
- UIから直接DBを触らない
- Repository経由でデータ操作する
- 画面ごとに必要なProviderを分ける

## 8. 実装AIへの禁止事項

- 旧SoleMuseum仕様を正本として使わない
- `specs/KICKXKICK_*` 以外を判断基準にしない
- 勝手にサーバー前提にしない
- 勝手にログイン機能を追加しない
- 勝手にSNS共有を実装しない
- 勝手に売買・相場管理アプリへ寄せない

## 9. 実装AIへの必須事項

作業前に確認すること:

```text
specs/KICKXKICK_SPRINT_PLAN.md
specs/KICKXKICK_DB_SPEC.md
specs/KICKXKICK_ROUTING_SPEC.md
specs/KICKXKICK_DESIGN_SYSTEM.md
```

Sprint1では必ず以下を参照する:

```text
specs/KICKXKICK_SPRINT1_INSTRUCTION.md
```

## 10. 完了報告ルール

作業後に報告すること:

- 作成ファイル
- 更新ファイル
- 実装した画面
- Provider一覧
- Repository一覧
- 未実装項目
- `flutter analyze` 結果
- 実機確認結果

## 11. 最重要ルール

Kick×Kickは管理アプリではない。

スニーカーをステッカー化して飾るアプリである。

Collectionは整列展示。
Stickerは自由配置。

この思想を実装でも崩さない。