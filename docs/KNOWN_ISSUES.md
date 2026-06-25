# Kick×Kick Known Issues

## 目的

この文書は、Kick×Kickの既知課題・一時仕様・修正済み事項を整理するためのもの。

リリースを止める課題と、MVP後に回せる課題を分けることで、Release 1.0の判断をしやすくする。

---

## 運用ルール

- 新しい問題を見つけたらこの文書へ追加する
- リリースを止める問題は Critical に入れる
- MVP後でもよい問題は Medium / Low に入れる
- バグではなく仕様として決めたものは「一時仕様」に入れる
- 修正済みのものは「修正済み」へ移す
- 実装前に必ず `docs/RELEASE_PLAN.md` と `docs/MVP_RELEASE_CHECKLIST.md` を確認する

---

## Critical

Release 1.0前に必ず解決する課題。

現時点で確認待ち:

- [ ] `flutter pub get` 未確認
- [ ] `flutter analyze` 未確認
- [ ] `flutter run` 未確認
- [ ] DB migration version5 未確認
- [ ] 新規登録の実機動作 未確認
- [ ] 編集の実機動作 未確認
- [ ] ShoeDetailScreenの実機動作 未確認
- [ ] 写真表示 / 写真保存の実機動作 未確認
- [ ] MY TOP5の実機動作 未確認
- [ ] 着用履歴の実機動作 未確認

Criticalに追加する条件:

- 起動できない
- `flutter analyze` の重大エラーが残る
- DB migrationで既存データが壊れる
- 新規登録できない
- 編集できない
- 詳細画面でクラッシュする
- 写真なし登録でクラッシュする
- Collectionが表示できない
- 削除できない

---

## High

できればRelease 1.0前に解決する課題。

現時点で確認待ち:

- [ ] CollectionのDisplay Title表示確認
- [ ] Collectionの状態表示確認
- [ ] HomeのDisplay Title対応確認
- [ ] Homeの最近追加対応確認
- [ ] 検索対象へのDisplay Title追加確認
- [ ] 検索対象へのSticker Text追加確認
- [ ] 状態フィルター確認
- [ ] Sticker最小実装確認

Highに追加する条件:

- 主要画面の表示崩れ
- TOP5表示の更新漏れ
- 写真表示の不具合
- Sticker表示の不具合
- 検索・フィルターの基本機能不具合

---

## Medium

MVP後でも対応可能な課題。

- [ ] UI文言の細かい改善
- [ ] 空状態の見た目改善
- [ ] ローディング表示の改善
- [ ] エラー表示の改善
- [ ] Collectionカードの微調整
- [ ] Stickerカードの見た目改善
- [ ] Homeの見た目改善

---

## Low

Release 1.0後に検討する課題。

- [ ] アニメーション追加
- [ ] テーマ追加
- [ ] アイコン微調整
- [ ] 高度なUX改善
- [ ] パフォーマンス最適化
- [ ] 細かなデザイン調整

---

## 一時仕様

Release 1.0では、以下を仕様として扱う。

### ブランド・モデル

- 自由入力ブランドはローカルDBの `brands` に保存する
- 自由入力ブランドはマスターJSONへ自動追加しない
- 自由入力モデルは靴1件の `modelName` として保存する
- 自由入力モデルはユーザー辞書・モデルマスターへ自動追加しない
- 誤入力は 靴詳細 → 編集 で修正する
- 自由入力モデル管理画面はMVPでは作らない
- ブランド・モデルFactory作業はMVPリリース後まで停止する

### Sticker

- StickerはRelease 1.0では最小実装とする
- 自由配置はRelease 1.0には含めない
- PNG出力はRelease 1.0には含めない
- SNS共有はRelease 1.0には含めない

### Premium / Backup

- Premium課金はRelease 1.0には含めない
- Google DriveバックアップはRelease 1.0には含めない
- クラウド同期はRelease 1.0には含めない
- ログイン機能はRelease 1.0には含めない

### 写真

- Release 1.0ではメイン写真を優先する
- 複数写真ギャラリーはRelease 1.0には含めない
- 箱写真・箱管理はRelease 1.0には含めない

---

## 修正済み / 完了済み

### ブランド・モデル検索

- [x] ブランド候補表示
- [x] モデル候補表示
- [x] Alias検索
- [x] searchKeywords検索
- [x] 数字検索
- [x] 自由入力ブランド対応
- [x] 自由入力モデル対応
- [x] 自由入力ブランドのローカルDB追加方針
- [x] 自由入力モデルを靴1件の `modelName` として保存する方針
- [x] ユーザー自由入力をマスターJSONへ自動追加しない方針

### 機能整理

- [x] お気に入りUIを削除
- [x] TOP5へ統一
- [x] DB互換のため `isFavorite` カラムは残す方針

### ドキュメント整理

- [x] `docs/HANDOFF_BRAND_MODEL_SEARCH.md`
- [x] `docs/HANDOFF_KICKXKICK_MVP_2026-06-25.md`
- [x] `docs/MVP_RELEASE_CHECKLIST.md`
- [x] `docs/RELEASE_PLAN.md`
- [x] `docs/POST_RELEASE.md`
- [x] `docs/TEST_PLAN.md`
- [x] `docs/README.md` 更新

---

## リリース判断メモ

Release 1.0に進むには、最低限以下を満たすこと。

- Criticalが0になる
- `flutter analyze` の重大エラーが0になる
- 実機で新規登録 → 詳細表示 → 編集 → Collection反映 が通る
- 写真あり / なしの保存が通る
- TOP5が通る
- 着用履歴が通る
- Sticker最小実装が表示できる

---

## 関連文書

- `docs/README.md`
- `docs/HANDOFF_KICKXKICK_MVP_2026-06-25.md`
- `docs/HANDOFF_BRAND_MODEL_SEARCH.md`
- `docs/MVP_RELEASE_CHECKLIST.md`
- `docs/RELEASE_PLAN.md`
- `docs/POST_RELEASE.md`
- `docs/TEST_PLAN.md`

---

## 最終メモ

この文書は「リリースを止める問題」と「後回しにしてよい問題」を分けるためのもの。

迷った場合は、Release 1.0の安定化を優先し、新機能は `docs/POST_RELEASE.md` へ退避する。
