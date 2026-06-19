# MVP Specification - SoleMuseum

## プロジェクト概要
SoleMuseum は、ユーザーのスニーカーコレクションを効率的に管理・展示するためのモバイルアプリケーションです。

## 開発期間
MVP段階での優先実装

## 技術方針
- **フレームワーク**: Flutter
- **言語**: Dart
- **UI**: Material 3
- **状態管理**: Riverpod
- **データベース**: SQLite
- **アーキテクチャ**: オフライン完結（サーバーなし、ログインなし）
- **開発優先度**: MVP優先（必要最小限の機能実装）

---

## MVP機能一覧

### 1. スニーカー登録機能
ユーザーが新しいスニーカー情報をアプリケーションに登録する機能。

**要件:**
- ブランド名の入力
- モデル名の入力
- サイズの入力
- 購入日の選択
- メモの入力（任意）
- 登録ボタンで保存

**UI要素:**
- テキスト入力フィールド（ブランド名、モデル名）
- 数値選択（サイズ）
- 日付ピッカー（購入日）
- テキストエリア（メモ）
- 保存ボタン

### 2. スニーカー一覧機能
登録されたスニーカーの一覧を表示する機能。

**要件:**
- 登録されたすべてのスニーカーをリスト形式で表示
- 各スニーカーの基本情報を表示
  - ブランド名
  - モデル名
  - サイズ
- 一覧から詳細画面へのナビゲーション
- スニーカーの新規追加へのナビゲーション

**表示内容:**
- スニーカーカードのリスト
- スニーカー削除機能（長押しまたはスワイプで削除オプション）

### 3. スニーカー詳細機能
個別のスニーカーの詳細情報を表示・編集する機能。

**要件:**
- 以下の情報を表示
  - ブランド名
  - モデル名
  - サイズ
  - 購入日
  - メモ
- 情報の編集機能
- 編集内容の保存機能
- 一覧への戻る機能

**画面レイアウト:**
- ヘッダーに戻るボタン
- 詳細情報の表示
- 編集ボタン
- 削除ボタン

---

## データモデル

### Sneaker スキーマ
```dart
class Sneaker {
  final String id;              // ユニークID
  final String brand;           // ブランド名
  final String model;           // モデル名
  final int size;               // サイズ
  final DateTime purchaseDate;  // 購入日
  final String? memo;           // メモ（任意）
  final DateTime createdAt;     // 作成日時
  final DateTime updatedAt;     // 更新日時

  Sneaker({
    required this.id,
    required this.brand,
    required this.model,
    required this.size,
    required this.purchaseDate,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

## 画面フロー

```
スプラッシュスクリーン
    ↓
一覧画面
    ├→ 新規登録画面 → 確認 → 一覧画面
    └→ 詳細画面
        ├→ 編集画面 → 確認 → 一覧画面
        └→ 削除確認 → 一覧画面
```

---

## データ永続化

### SQLite
- sqflite パッケージを使用
- オフライン環境での完全対応
- 高速なクエリ処理

**実装方針:**
- CRUD操作の実装
- トランザクション管理
- エラーハンドリング
- データ検証

---

## 状態管理

### Riverpod
- `FutureProvider`: 非同期データ取得
- `StateNotifier`: 状態変更
- `ChangeNotifier`: 状態監視

**実装パターン:**
- Repository パターンで SQLite 操作を抽象化
- Provider で状態を一元管理
- ウィジェット から Provider を参照

---

## UI/UX方針

### Material 3
- 最新の Material Design 言語
- 動的カラーシステム対応
- テーマ統一

### デザイン原則
- シンプルで直感的なインターフェース
- 最小限のナビゲーション
- 明確なアクションボタン

### レスポンシブデザイン
- 様々なスクリーンサイズに対応
- 縦向き表示をメインサポート

---

## マイルストーン

### Phase 1: 基本機能実装
- [ ] プロジェクトセットアップ
- [ ] SQLite データベース設計
- [ ] Riverpod プロバイダー設計
- [ ] スニーカー登録機能
- [ ] スニーカー一覧表示
- [ ] スニーカー詳細表示

### Phase 2: 追加機能
- [ ] 編集機能の実装
- [ ] 削除機能の実装
- [ ] UI/UXの改善
- [ ] Material 3 テーマ設定

### Phase 3: テスト・リリース
- [ ] ユニットテスト
- [ ] ウィジェットテスト
- [ ] 統合テスト
- [ ] ビルド・リリース準備

---

## 非スコープ（今回は実装しない）

- クラウドバックアップ
- ソーシャル機能（共有、フォロー）
- 画像アップロード
- 検索・フィルタリング
- 複雑なダッシュボード
- 多言語対応
- ユーザー認証

これらの機能は MVP 以降のバージョンで検討します。

---

## 参考資料

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Documentation](https://riverpod.dev)
- [sqflite](https://pub.dev/packages/sqflite)
- [Material 3 Design](https://m3.material.io)
