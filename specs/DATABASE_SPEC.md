# DATABASE_SPEC.md

## 概要

SoleMuseum MVPで使用するローカルデータベース仕様。

Flutter + SQLite (Drift) を前提とする。

---

# Database

## Name

```text
solemuseum.db
```

---

# Table: shoes

スニーカー情報を保存するメインテーブル

---

## Schema

| Column | Type | Nullable | Description |
|----------|----------|----------|----------|
| id | INTEGER | NO | Primary Key |
| brand | TEXT | NO | ブランド名 |
| model_name | TEXT | NO | モデル名 |
| size | REAL | YES | サイズ(cm) |
| purchase_date | TEXT | YES | 購入日 |
| memo | TEXT | YES | メモ |
| image_path | TEXT | YES | メイン画像 |
| created_at | TEXT | NO | 登録日時 |
| updated_at | TEXT | NO | 更新日時 |

---

## Example

```json
{
  "id": 1,
  "brand": "Nike",
  "model_name": "Air Jordan 1 Chicago",
  "size": 27.5,
  "purchase_date": "2026-06-21",
  "memo": "初めて購入したAJ1",
  "image_path": "/storage/emulated/0/Pictures/aj1.jpg",
  "created_at": "2026-06-21T10:00:00",
  "updated_at": "2026-06-21T10:00:00"
}
```

---

# Index

## IDX_SHOES_BRAND

```sql
CREATE INDEX idx_shoes_brand
ON shoes(brand);
```

---

## IDX_SHOES_MODEL_NAME

```sql
CREATE INDEX idx_shoes_model_name
ON shoes(model_name);
```

---

# Sorting

## Default

```text
created_at DESC
```

新しい順

---

# Search

## Target

- brand
- model_name

---

# Statistics

## Total Shoes

```sql
SELECT COUNT(*)
FROM shoes;
```

---

## Total Brands

```sql
SELECT COUNT(DISTINCT brand)
FROM shoes;
```

---

## Monthly Added

```sql
SELECT COUNT(*)
FROM shoes
WHERE created_at >= start_of_month;
```

---

# MVP Scope

## Include

- shoes table
- search
- statistics

## Exclude

- user table
- cloud sync
- authentication
- market price
- AI analysis

---

# Future Tables

## shoe_images

複数画像対応

```text
shoe_id
image_path
sort_order
```

---

## brands

ブランド管理

```text
id
name
```

---

# DESIGN PRINCIPLE

MVPではテーブルを増やさない。

まずは

```text
shoes
```

1テーブルで運用する。

機能追加時に正規化を検討する。