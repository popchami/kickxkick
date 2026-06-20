# NAVIGATION_SPEC.md

## 概要

SoleMuseum MVPの画面遷移仕様を定義する。

本仕様書はFlutter Router実装の基準とする。

---

# Navigation Structure

```text
Home
├─ Shoe Detail
│  └─ Shoe Edit
│
├─ Collection
│  └─ Shoe Detail
│      └─ Shoe Edit
│
├─ Add Shoe
│
└─ Settings
```

---

# Bottom Navigation

## Home

```text
ホーム
```

Route

```text
/
```

---

## Collection

```text
コレクション
```

Route

```text
/collection
```

---

## Add Shoe

```text
追加
```

Route

```text
/shoe/new
```

---

## Settings

```text
設定
```

Route

```text
/settings
```

---

# Screen Routes

## Home Screen

Route

```text
/
```

File

```text
home_screen.dart
```

---

## Collection Screen

Route

```text
/collection
```

File

```text
collection_screen.dart
```

---

## Shoe Detail Screen

Route

```text
/shoe/:id
```

Example

```text
/shoe/1
```

File

```text
shoe_detail_screen.dart
```

---

## Shoe Form Screen

New

```text
/shoe/new
```

Edit

```text
/shoe/:id/edit
```

Examples

```text
/shoe/new
```

```text
/shoe/1/edit
```

File

```text
shoe_form_screen.dart
```

---

## Settings Screen

Route

```text
/settings
```

File

```text
settings_screen.dart
```

---

# Navigation Rules

## Home → Detail

タップ対象

```text
注目の展示
最近のコレクション
```

遷移先

```text
/shoe/:id
```

---

## Collection → Detail

タップ対象

```text
スニーカーカード
```

遷移先

```text
/shoe/:id
```

---

## Detail → Edit

タップ対象

```text
編集
```

遷移先

```text
/shoe/:id/edit
```

---

## Add Button

タップ対象

```text
追加
```

遷移先

```text
/shoe/new
```

---

# Back Navigation

## Rule

常に前画面へ戻る

---

## Examples

```text
Detail → Collection
```

```text
Edit → Detail
```

```text
Settings → Home
```

---

# Deep Link

MVPでは未対応

---

# Authentication

MVPでは未対応

---

# State Preservation

Bottom Navigation切替時

保持する

対象

```text
スクロール位置
検索状態
フィルタ状態
```

---

# DESIGN PRINCIPLE

ユーザーが迷わないことを最優先とする。

画面階層は最大3階層まで。

```text
Home
↓
Detail
↓
Edit
```

以上の深さを作らない。