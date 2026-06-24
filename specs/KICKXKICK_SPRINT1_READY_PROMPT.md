# Kick×Kick Sprint1 Ready Prompt

このファイルは、Codex / Copilot Chat にそのまま渡すためのSprint1開始プロンプトです。

---

## Copy Prompt

```text
このリポジトリ popchami/solemuseum を Kick×Kick の開発リポジトリとして扱ってください。

リポジトリ名に solemuseum が残っていますが、現在のアプリ名・仕様の正本は Kick×Kick です。
旧SoleMuseum仕様は参照しないでください。

まず以下の仕様書を確認してください。

- specs/KICKXKICK_SPEC.md
- specs/KICKXKICK_PRODUCT.md
- specs/KICKXKICK_UI_SPEC.md
- specs/KICKXKICK_DATA.md
- specs/KICKXKICK_DB_SPEC.md
- specs/KICKXKICK_ROUTING_SPEC.md
- specs/KICKXKICK_DESIGN_SYSTEM.md
- specs/KICKXKICK_IMPLEMENTATION_RULES.md
- specs/KICKXKICK_SPRINT_PLAN.md
- specs/KICKXKICK_SPRINT1_INSTRUCTION.md

Sprint1を実装してください。

Sprint1で実装するもの:

- アプリ起動確認
- Bottom Navigation
- 中央FAB
- スニーカー登録
- スニーカー詳細
- 写真登録（Sprint1ではメイン写真1枚でよい）
- 登録済みスニーカー表示
- TOP5登録 / 入れ替え
- Home上部TOP5表示
- 今日履いた
- 過去日追加
- 着用回数表示
- 初回着用時に新品から着用済みへ自動変更

Sprint1で実装しないもの:

- Collection棚編集
- Sticker Board自由配置
- ステッカー生成
- 自動背景削除
- PNG出力
- バックアップ
- 復元
- Premium購入処理
- SNS共有
- 通知

重要:

- Kick×Kickは管理アプリではなく、スニーカーをステッカー化して飾るアプリです。
- ただしSprint1では、飾る機能の前段階として登録・詳細・TOP5・着用履歴を完成させてください。
- 既存の実機動作していたFlutter/Android構成は壊さないでください。
- 旧SoleMuseum由来の命名が残っている場合は、Kick×Kick仕様に合わせて必要最小限で修正してください。

作業前に、まず実装計画を提示してください。

作業後に以下を報告してください。

- 作成したファイル
- 更新したファイル
- 実装した画面
- 実装したProvider
- 実装したRepository
- 未実装項目
- flutter analyze の結果
- 実機 / エミュレータ確認結果
```

---

## Note

Sprint1の目的は、まず動くKick×Kickの土台を作ることです。

CollectionとStickerはSprint2以降で実装します。
