# Kick×Kick Model Master Coverage v1.7

## Purpose

Kick×Kick のブランド・モデルマスター資産の育成状況を管理する。

---

## Coverage Policy

```text
1. 国内流通リファレンスを確認する
2. まずブランド名を国内流通リファレンスに近づける
3. モデルはブランドごとに段階追加する
4. Alias / searchKeywords はモデル追加時に追加する
5. 低確度モデルや広すぎる検索語は追加しない
```

---

## Status Definition

```text
PASS
- MVPで十分な品質
- 主要モデル / Alias / searchKeywords / Canonical Name が揃っている

BRAND_ONLY
- ブランド名は登録済み
- モデル / Alias / searchKeywords は未追加または未監査

WARNING
- MVPでは使えるが、AliasやsearchKeywordsに追加余地がある

TODO
- モデル不足、Alias不足、searchKeywords不足が目立つ
```

---

## Tier S Coverage

| Brand | Priority S Models | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---:|---:|---|---|---|---|---|
| Nike | 16 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| Air Jordan | 12 | PASS | PASS | PASS | PASS | PASS | AJ/J/Jordan連結表記と日本語検索を補強済み。 |
| adidas | 12 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| New Balance | 20 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| ASICS | 12 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |

---

## Tier A Coverage

| Brand | Priority A Models | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---:|---:|---|---|---|---|---|
| PUMA | 6 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| Converse | 6 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| Vans | 6 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |
| Reebok | 6 | PASS | PASS | PASS | PASS | PASS | ABC-MART差分監査は継続。 |

---

## Tier B Coverage

| Brand | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---|---|---|---|---|---|
| HOKA | PASS | PASS | PASS | PASS | PASS | 代表6モデル追加済み。 |
| Saucony | PASS | PASS | PASS | PASS | PASS | 代表6モデル追加済み。 |
| SALOMON | PASS | PASS | PASS | PASS | PASS | 代表6モデル追加済み。 |
| MERRELL | TODO | TODO | TODO | TODO | BRAND_ONLY | ABC-MART掲載確認済み。モデルは次回以降に段階追加。 |
| BROOKS | TODO | TODO | TODO | TODO | BRAND_ONLY | ABC-MART掲載確認済み。モデルは次回以降に段階追加。 |

---

## Tier C Brand Registry

Tier Cは、国内流通リファレンスに掲載されるブランド名を先行登録した状態。

```text
HAWKINS / FILA / byA / ABC SELECT / NUOVO / SKECHERS / Danner / STEFANO ROSSI / Timberland / SPERRY TOPSIDER / le coq sportif / DESCENTE / COLE HAAN / ROCKPORT / SYUNSOKU / Dr.Martens / PATRICK / TEVA / crocs / UNDER ARMOUR / HUNTER / JOLI ENCORE / IFME / G.C.MORELLI / HARUTA / SUPERGA / JEWEL / RED WING / A+ / AIGLE / AKTR / AMBITIOUS / BENTER / BIRKENSTOCK / BLUNDSTONE / BUNKER / BUTTERFLYTWISTS / CHAMPION / CLARKS / COLUMBUS / CORSO NAPOLEONE / COXX BORBA / EVE / FLUCHOS / FRED PERRY / FOOTJOY / GAVIC / GENTILE / GIANNI SIMONE / HARRIS / HI-TEC / HOME COLLECT / HOME EXE / HYPER JUMPER / Ipanema / K-SWISS / LACOSTE / LIBERTY HOUSE / MINNETONKA / molten / MONTRRE / MOONSTAR / NEW ERA / PANSY / PEACEPARK / PEDAG / POLO R.LAUREN / POLSA / REGETA / SKA / SHAKA / STANCE SOCKS / STILMODA / TEXCY / UMBRO / zamst
```

状態:

```text
Brand Registry: PASS
Model Coverage: TODO
Alias: TODO
searchKeywords: TODO
```

---

## Completed Work

```text
2026-06-25
- Tier S ブランド・モデル初期登録

2026-06-26
- Tier S Alias / searchKeywords 補強
- Tier A 4ブランドと代表モデルを追加

2026-06-28
- HOKAをTier B追加
- HOKA Alias / searchKeywordsを追加

2026-06-29 v0.4.0
- Saucony / SALOMONをTier B追加
- Saucony / SALOMON の代表モデル、Alias、searchKeywordsを追加

2026-06-29 v0.5.0
- ABC-MART掲載ブランドを基準にbrands.jsonを90ブランドへ拡張
- MERRELL / BROOKSをTier B brand-onlyとして追加
- Tier Cブランドをbrand-onlyとして先行登録
```

---

## Next Work

```text
1. MERRELL / BROOKS のモデル追加
2. Tier Cブランドのモデル追加を優先度順に進める
3. Tier S / A / B のABC-MART差分監査を継続
4. Search MVPテストケースを実機またはFlutterテストで実施
5. data/*.json と app/assets/data/*.json の同期自動化
```

---

## Quality Goal

代表モデルだけで止めず、国内流通リファレンスのブランド・モデル量に近づける。

ただし、低確度モデルや広すぎるAlias/searchKeywordsは追加しない。
