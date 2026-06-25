# Kick×Kick Model Master Coverage v1.2

## Purpose

このファイルは、Kick×Kick のモデルマスター資産の育成状況を管理する。

目的は、モデル候補・Alias・searchKeywords・正式表記の整備状況をブランドごとに見える化することである。

---

## Coverage Policy

Kick×Kick では、モデルマスターを以下の観点で育てる。

```text
1. 主要モデルが候補に出る
2. Aliasで見つかる
3. 数字検索で見つかる
4. 日本語検索で見つかる
5. 保存名が正式表記に統一される
6. ブランドとモデルの整合性が保たれる
```

---

## Status Definition

```text
PASS
- MVPで十分な品質
- 主要モデル / Alias / searchKeywords / Canonical Name が揃っている

WARNING
- MVPでは使えるが、AliasやsearchKeywordsに追加余地がある

TODO
- モデル不足、Alias不足、searchKeywords不足が目立つ

BLOCKED
- 外部要因や仕様未確定で進められない
```

---

## Tier S Coverage

| Brand | Priority S Models | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---:|---:|---|---|---|---|---|
| Nike | 16 | PASS | PASS | PASS | PASS | PASS | Air Force 1 / Air Max / Dunk / P-6000 / Vomero 5 などMVP主要検索を補強済み。 |
| Air Jordan | 12 | PASS | PASS | PASS | PASS | PASS | AJ/J/Jordan連結表記と日本語検索を補強済み。1桁数字単体は追加しない。 |
| adidas | 12 | PASS | PASS | PASS | PASS | PASS | Samba / Gazelle / Campus / Forum / Adimatic / Ultraboost などを補強済み。 |
| New Balance | 20 | PASS | PASS | PASS | PASS | PASS | 530 / 550 / 574 / 9060 / 990v1〜v6 / 2002R / 1906R を補強済み。 |
| ASICS | 12 | PASS | PASS | PASS | PASS | PASS | GT-2160 / GEL-1130 / GEL-Kayano 14 / GEL-NYC / Novablast / Superblast などを補強済み。 |

---

## Tier S Priority Model Targets

### Nike

```text
Air Force 1
Air Max 1
Air Max 90
Air Max 95
Air Max 97
Air Max Plus
Dunk Low
Dunk High
SB Dunk Low
P-6000
Zoom Vomero 5
Pegasus
Invincible
Cortez
Shox
TC 7900
```

### Air Jordan

```text
Air Jordan 1
Air Jordan 2
Air Jordan 3
Air Jordan 4
Air Jordan 5
Air Jordan 6
Air Jordan 11
Air Jordan 12
Air Jordan 13
Air Jordan 14
Jordan Spizike
Jordan Legacy 312
```

### adidas

```text
Samba
Gazelle
Campus 00s
Superstar
Stan Smith
Handball Spezial
SL 72
Forum Low
Forum Mid
Adimatic
Ultraboost
Yeezy 350
```

### New Balance

```text
530
550
574
576
580
327
725
740
9060
2002R
1906R
990v1
990v2
990v3
990v4
990v5
990v6
991
992
993
```

### ASICS

```text
GT-2160
GEL-1130
GEL-1090
GEL-Kayano 14
GEL-NYC
GEL-Nimbus 9
GEL-Lyte III
GEL-Lyte V
Novablast
Superblast
EX89
Japan S
```

---

## Review Checklist

各モデルは以下を満たすこと。

```text
- modelName が正式表記である
- Alias が検索用に入っている
- searchKeywords に数字・連結表記・日本語表記が必要分だけ入っている
- searchKeywords に広すぎる語を入れていない
- brandId が正しい
- 同一モデルが重複登録されていない
```

---

## Good Data Example

```json
{
  "id": "nike_air_max_95",
  "brandId": "nike",
  "brandName": "Nike",
  "modelName": "Air Max 95",
  "aliases": ["AM95", "Airmax95"],
  "searchKeywords": ["95", "AirMax95", "エアマックス95"],
  "category": "lifestyle",
  "source": "master"
}
```

---

## Bad Data Example

```json
{
  "modelName": "Air Max 95",
  "aliases": [],
  "searchKeywords": ["Air", "Max", "9"]
}
```

理由:

```text
- Alias不足
- Air / Max が広すぎる
- 9 が広すぎる
```

---

## Completed Work

```text
2026-06-25
- MODEL_MASTER/NIKE.md を v2.0 に更新
- Canonical Name / Alias / searchKeywords / category / source を追加
- Nike を MVP基準で WARNING まで引き上げ

2026-06-26
- data/aliases.json を v0.1.1 に更新
- data/search_keywords.json を v0.1.2 に更新
- app/assets/data/aliases.json と app/assets/data/search_keywords.json を同期
- Tier S 5ブランドをMVP基準でPASSに更新
- 低確度モデル追加は行わず、既存Tier Sモデルの検索補助を補強
```

---

## Next Work

```text
1. Search MVPテストケースを実機またはFlutterテストで実施
2. data/*.json と app/assets/data/*.json の同期自動化
3. Tier Aブランド候補を別PR/別作業で追加検討
4. Tier Sの追加モデルは実ユーザー入力ログが溜まってから判断
```

---

## Quality Goal

Tier S ブランドについて、ユーザーが以下の入力で目的モデルへ到達できること。

```text
95 -> Air Max 95
97 -> Air Max 97
AF1 -> Air Force 1
P6000 -> P-6000
Vomero5 -> Zoom Vomero 5
AJ1 -> Air Jordan 1
Jordan11 -> Air Jordan 11
550 -> 550
990 -> 990v1〜990v6
NB990v6 -> 990v6
9060 -> 9060
2160 -> GT-2160
1130 -> GEL-1130
Kayano14 -> GEL-Kayano 14
GelKayano14 -> GEL-Kayano 14
Samba -> Samba
Campus -> Campus 00s
ForumLow -> Forum Low
フォーラムロー -> Forum Low
ゲルNYC -> GEL-NYC
```
