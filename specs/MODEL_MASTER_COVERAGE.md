# Kick×Kick Model Master Coverage v1.5

## Purpose

このファイルは、Kick×Kick のモデルマスター資産の育成状況を管理する。

目的は、モデル候補・Alias・searchKeywords・正式表記の整備状況をブランドごとに見える化することである。

---

## Coverage Policy

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

## Tier A Coverage

| Brand | Priority A Models | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---:|---:|---|---|---|---|---|
| PUMA | 6 | PASS | PASS | PASS | PASS | PASS | Suede / Palermo / Speedcat / Clyde / RS-X / Basket を高確度で追加。 |
| Converse | 6 | PASS | PASS | PASS | PASS | PASS | Chuck Taylor All Star / Chuck 70 / One Star / Jack Purcell / Weapon / Run Star Hike を追加。 |
| Vans | 6 | PASS | PASS | PASS | PASS | PASS | Old Skool / Authentic / Classic Slip-On / Sk8-Hi / Era / Knu Skool を追加。 |
| Reebok | 6 | PASS | PASS | PASS | PASS | PASS | Club C / Classic Leather / Instapump Fury / Workout Plus / Freestyle / Question を追加。 |

---

## Tier B Coverage

| Brand | Priority B Models | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---:|---:|---|---|---|---|---|
| HOKA | 6 | PASS | PASS | PASS | PASS | PASS | Bondi 9 / Clifton 10 / Speedgoat 7 / Arahi 8 / Transport 2 / Challenger 8 にAliasと日本語検索を追加済み。 |

---

## Tier S Priority Model Targets

```text
Nike: Air Force 1 / Air Max 1 / Air Max 90 / Air Max 95 / Air Max 97 / Air Max Plus / Dunk Low / Dunk High / SB Dunk Low / P-6000 / Zoom Vomero 5 / Pegasus / ZoomX Invincible Run / Cortez / Shox R4 / TC 7900
Air Jordan: Air Jordan 1 / 2 / 3 / 4 / 5 / 6 / 11 / 12 / 13 / 14 / Jordan Spizike / Jordan Legacy 312
adidas: Samba / Gazelle / Campus 00s / Superstar / Stan Smith / Handball Spezial / SL 72 / Forum Low / Forum Mid / Adimatic / Ultraboost / Yeezy 350
New Balance: 530 / 550 / 574 / 576 / 580 / 327 / 725 / 740 / 9060 / 2002R / 1906R / 990v1〜v6 / 991 / 992 / 993
ASICS: GT-2160 / GEL-1130 / GEL-1090 / GEL-Kayano 14 / GEL-NYC / GEL-Nimbus 9 / GEL-Lyte III / GEL-Lyte V / Novablast / Superblast / EX89 / Japan S
```

---

## Tier A Priority Model Targets

```text
PUMA: Suede / Palermo / Speedcat / Clyde / RS-X / Basket
Converse: Chuck Taylor All Star / Chuck 70 / One Star / Jack Purcell / Weapon / Run Star Hike
Vans: Old Skool / Authentic / Classic Slip-On / Sk8-Hi / Era / Knu Skool
Reebok: Club C / Classic Leather / Instapump Fury / Workout Plus / Freestyle / Question
```

---

## Tier B Priority Model Targets

```text
HOKA: Bondi 9 / Clifton 10 / Speedgoat 7 / Arahi 8 / Transport 2 / Challenger 8
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

## Completed Work

```text
2026-06-25
- Tier S ブランド・モデル初期登録

2026-06-26
- Tier S Alias / searchKeywords 補強
- Tier S 5ブランドをMVP基準でPASSに更新

2026-06-26 v0.2.0
- Tier A 4ブランドを追加
- PUMA / Converse / Vans / Reebok の代表モデルを各6件追加
- Tier A Alias / searchKeywords を追加

2026-06-28 v0.3.0
- Tier BとしてHOKAを追加
- HOKAの高確度代表モデル6件を追加

2026-06-28 v0.3.1
- HOKA Alias / searchKeywords を追加
- HOKAをPASSに更新
- app/assets/data/aliases.json / search_keywords.json を同期更新
```

---

## Next Work

```text
1. Search MVPテストケースを実機またはFlutterテストで実施
2. data/*.json と app/assets/data/*.json の同期自動化
3. Tier B/Cブランド候補を別作業で追加検討
4. Tier S/A/Bの追加モデルは実ユーザー入力ログが溜まってから判断
```

---

## Quality Goal

Tier S / Tier A / Tier B ブランドについて、ユーザーが主要な略称・数字・日本語入力で目的モデルへ到達できること。

Tier BはHOKAをPASS化済み。次のTier B/Cは、低確度モデルを避けて段階追加する。
