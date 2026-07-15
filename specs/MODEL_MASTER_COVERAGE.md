# Kick×Kick Model Master Coverage v2.9

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

MODEL_STARTED
- ブランド名は登録済み
- 高確度モデルを一部追加済み
- Alias / searchKeywords も追加済み
- ただし代表モデル量はまだ拡張余地がある

MERGE_READY
- ブランド名は登録済み
- 高確度モデル / Alias / searchKeywords は検証済み
- ただし本体JSONとapp/assets/dataへの同期反映は未実施

MERGE_READY_AUDITED
- MERGE_READYに加えて、同期スクリプトと除外語監査が明文化済み
- 実行環境で同期スクリプトを走らせれば本体JSON反映できる状態

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
| MERRELL | PASS | PASS | PASS | PASS | PASS | 代表5モデル追加済み。広すぎるPeak/Glove単体は未追加。 |
| BROOKS | PASS | PASS | PASS | PASS | PASS | 代表8モデル追加済み。広すぎるGhost/Trail/Max単体は未追加。 |

---

## Tier C Coverage

| Brand | Model Coverage | Alias | searchKeywords | Canonical Name | Status | Notes |
|---|---|---|---|---|---|---|
| SKECHERS | PASS 16 | PASS | PASS | PASS | PASS | 16件へ拡張。一般語単体は除外し、識別性の高いフル名称・ブランド連結語のみ採用。 |
| crocs | PASS 10 | PASS | PASS | PASS | PASS | 10件へ拡張。モデル固有の複合語のみ採用し、広すぎる単独語は除外。 |
| Dr.Martens | PASS 15 | PASS | PASS | PASS | PASS | 15モデルを本体JSONとapp/assets/dataへ同期済み。広すぎるAlias/searchKeywordsは除外済み。 |
| Timberland | PASS 6 | PASS | PASS | PASS | PASS | 公式・主要流通で識別可能な6モデルを追加。一般語単体は除外。 |
| FILA | PASS 6 | PASS | PASS | PASS | PASS | 高確度6モデルを追加。ブランド・一般語単体は除外。 |
| Danner | PASS 6 | PASS | PASS | PASS | PASS | 高確度6モデルを追加。ブランド・一般語単体は除外。 |

---

## Tier C Brand Registry

Tier Cは、国内流通リファレンスに掲載されるブランド名を先行登録した状態。

```text
HAWKINS / FILA / byA / ABC SELECT / NUOVO / Danner / STEFANO ROSSI / Timberland / SPERRY TOPSIDER / le coq sportif / DESCENTE / COLE HAAN / ROCKPORT / SYUNSOKU / PATRICK / TEVA / UNDER ARMOUR / HUNTER / JOLI ENCORE / IFME / G.C.MORELLI / HARUTA / SUPERGA / JEWEL / RED WING / A+ / AIGLE / AKTR / AMBITIOUS / BENTER / BIRKENSTOCK / BLUNDSTONE / BUNKER / BUTTERFLYTWISTS / CHAMPION / CLARKS / COLUMBUS / CORSO NAPOLEONE / COXX BORBA / EVE / FLUCHOS / FRED PERRY / FOOTJOY / GAVIC / GENTILE / GIANNI SIMONE / HARRIS / HI-TEC / HOME COLLECT / HOME EXE / HYPER JUMPER / Ipanema / K-SWISS / LACOSTE / LIBERTY HOUSE / MINNETONKA / molten / MONTRRE / MOONSTAR / NEW ERA / PANSY / PEACEPARK / PEDAG / POLO R.LAUREN / POLSA / REGETA / SKA / SHAKA / STANCE SOCKS / STILMODA / TEXCY / UMBRO / zamst
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

2026-07-01 v0.5.1
- MERRELL / BROOKS のモデル、Alias、searchKeywordsを追加
- data/*.json と app/assets/data/*.json の同期状態を回復

2026-07-02 v0.5.2
- SKECHERS の代表モデル、Alias、searchKeywordsを追加開始
- data/models・aliases・search_keywords と app/assets/data 側を同期

2026-07-03 v0.5.3
- SKECHERSを8モデルまで拡張
- data/models・aliases・search_keywords と app/assets/data 側を同期

2026-07-04 v0.5.4
- crocsを4モデル追加開始
- data/models・aliases・search_keywords と app/assets/data 側を同期

2026-07-07 v0.5.5-staging
- Dr.Martens `1460` / `1461` を検証済みmerge-ready stagingへ更新
- 本体JSON反映前に広すぎるAlias/searchKeywordsを除外

2026-07-08 v0.5.6-staging
- Dr.Martensを15モデルへ拡張
- Alias / searchKeywordsも同じ15モデルに合わせて拡張
- 本体JSON反映前のmerge-ready stagingとして管理

2026-07-09 v0.5.7-audit
- Dr.Martens stagingをmerge-ready-auditedへ更新
- 同期スクリプト `data/sync_dr_martens_v0.5.7.py` を正式手順として明記

2026-07-10 v0.5.7
- Dr.Martens 15モデルを本体JSONへ反映
- Alias / searchKeywordsを同期
- data/*.json と app/assets/data/*.json の一致を検証
```

---

## Next Work

```text
1. Search MVPテストケース実施
2. 次のTier Cブランドを1ブランド集中で追加（Danner完了後）
3. SKECHERS / crocs の国内流通差分監査を継続
4. Tier S / A / B のABC-MART差分監査を継続
```

---

## Quality Goal

代表モデルだけで止めず、国内流通リファレンスのブランド・モデル量に近づける。

ただし、低確度モデルや広すぎるAlias/searchKeywordsは追加しない。


2026-07-11 v0.5.8
- SKECHERSを16モデルへ拡張
- data/*.json と app/assets/data/*.json の一致を検証


2026-07-13 v0.6.0
- Timberland 6モデルを追加
- Alias / searchKeywordsを高純度監査
- data/*.json と app/assets/data/*.json を同期

2026-07-14 v0.6.1
- FILA 6モデルを追加
- Alias / searchKeywordsを高純度監査
- data/*.json と app/assets/data/*.json を同期

2026-07-15 v0.6.2
- Danner 6モデルを追加
- Alias / searchKeywordsを高純度監査
- data/*.json と app/assets/data/*.json を同期
