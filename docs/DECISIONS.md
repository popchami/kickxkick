# DECISIONS.md

## Decision 001

### Riverpod採用

採用理由

- Flutter標準に近い
- 学習コストが低い
- MVPに十分

却下

- Bloc
- Provider

---

## Decision 002

### Drift採用

採用理由

- 型安全
- SQLite利用可能
- Flutter実績多数

却下

- Hive
- Isar

---

## Decision 003

### Offline First

採用理由

- 個人利用中心
- ログイン不要
- MVP高速化

却下

- Firebase
- Supabase

---

## Decision 004

### Dark Theme First

採用理由

- Museumコンセプト
- スニーカー写真が映える
- 高級感

---

## Decision 005

### MVP範囲

含む

- 登録
- 一覧
- 詳細
- 編集
- 削除

含まない

- AI鑑定
- 相場取得
- SNS共有
- 売買
- クラウド同期
```