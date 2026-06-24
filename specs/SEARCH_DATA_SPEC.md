# Kick×Kick Search Data Spec v1.0

## Purpose

この仕様書は、Kick×Kick のブランド・モデル検索で使う検索データ構造を定義する。

目的は、ユーザーが正式名称を知らなくても、ブランド・モデル候補に素早く到達できる検索体験を作ることである。

---

## User Goal

ユーザーは以下のような入力で検索する。

```text
AJ1
AF1
AM95
990
NB550
GT2160
XT6
エアマックス
カヤノ
```

検索結果では、Aliasではなく正式なブランド名・モデル名を表示する。

---

## Search Targets

検索対象は以下の3つ。

```text
Brand
Model
Alias
```

---

## Core Data Object

検索用データは、最終的に以下の形へ変換できること。

```json
{
  "id": "nike_air_max_95",
  "brandId": "nike",
  "brandName": "Nike",
  "modelName": "Air Max 95",
  "displayName": "Nike Air Max 95",
  "aliases": [
    "AM95",
    "Airmax95",
    "エアマックス95"
  ],
  "series": "Air Max",
  "category": "lifestyle",
  "priority": 90,
  "source": "model_master"
}
```

---

## Field Definition

### id

検索候補の一意ID。

形式:

```text
{brand_id}_{model_slug}
```

例:

```text
nike_air_max_95
new_balance_990v6
asics_gt_2160
```

---

### brandId

ブランドID。

英小文字のスネークケースを使う。

例:

```text
nike
air_jordan
new_balance
onitsuka_tiger
```

---

### brandName

ユーザーに表示する正式ブランド名。

例:

```text
Nike
Air Jordan
New Balance
Onitsuka Tiger
```

---

### modelName

ユーザーに表示する正式モデル名。

例:

```text
Air Max 95
Air Jordan 1 High OG
990v6
GEL-Kayano 14
```

---

### displayName

検索結果に表示する名称。

基本形式:

```text
{brandName} {modelName}
```

例:

```text
Nike Air Max 95
New Balance 990v6
```

---

### aliases

検索専用の別名。

表示には使わない。

例:

```text
AF1
AM95
AJ1
NB550
GT2160
エアフォース
エアマックス
```

---

### series

モデルシリーズ名。

シリーズ検索に使う。

例:

```text
Air Max
Air Force 1
Dunk
990 Series
GEL-Kayano
XT Series
```

---

### category

モデルの大まかなカテゴリ。

MVPでは厳密な分類にしすぎない。

候補:

```text
lifestyle
running
basketball
skateboarding
outdoor
trail
tennis
training
sandal
boot
other
```

---

### priority

検索結果の並び順に使う重要度。

数値が高いほど上に出る。

目安:

```text
100: 超定番 / 最重要
90: 高頻度モデル
70: 代表モデル
50: 補完モデル
30: 低頻度モデル
```

例:

```text
Air Force 1: 100
Air Max 95: 95
New Balance 990v6: 95
Karhu Fusion 2.0: 70
```

---

### source

検索候補の出どころ。

候補:

```text
brand_master
model_master
alias_master
user_input
```

---

## Brand Search Object

ブランド検索用データは以下。

```json
{
  "id": "new_balance",
  "brandName": "New Balance",
  "aliases": [
    "NB",
    "ニューバランス"
  ],
  "tier": "S",
  "priority": 95
}
```

---

## Alias Rule

Aliasは検索専用であり、保存値・表示名にはしない。

例:

```text
検索入力: AJ1
表示: Air Jordan 1
保存: Air Jordan 1
```

---

## Match Type

検索時は以下の一致タイプを使う。

```text
exact
alias_exact
prefix
contains
normalized
```

優先順位:

```text
1. exact
2. alias_exact
3. prefix
4. contains
5. normalized
```

---

## Normalization Rule

検索前に入力値と検索対象を正規化する。

正規化内容:

```text
- 大文字小文字を無視
- 半角全角を可能な範囲で同一扱い
- 空白を無視
- ハイフンを無視
- ドットを無視
- 日本語カタカナ表記をAliasで補完
```

例:

```text
GT2160 -> GT-2160
Airmax95 -> Air Max 95
NB 550 -> NB550
Cloud5 -> Cloud 5
```

---

## Search Result Object

検索結果は以下の形で扱う。

```json
{
  "id": "air_jordan_air_jordan_1_high_og",
  "brandName": "Air Jordan",
  "modelName": "Air Jordan 1 High OG",
  "displayName": "Air Jordan Air Jordan 1 High OG",
  "matchedText": "AJ1",
  "matchType": "alias_exact",
  "priority": 98
}
```

---

## Ranking Rule

検索結果の並び順は以下。

```text
1. matchType priority
2. model priority
3. brand tier
4. shorter displayName
5. alphabetical order
```

例:

検索:

```text
990
```

結果:

```text
New Balance 990v6
New Balance 990v5
New Balance 990v4
New Balance 990v3
New Balance 990v2
New Balance 990v1
```

---

## No Result Rule

候補が見つからない場合も登録を止めない。

表示:

```text
候補が見つかりません
自由入力で登録できます
```

保存時は source を user_input にする。

---

## Free Input Object

自由入力時は以下の形で扱う。

```json
{
  "brandName": "User Brand",
  "modelName": "User Model",
  "source": "user_input"
}
```

---

## MVP Scope

MVPでは以下を実装対象にする。

```text
- ブランド名検索
- モデル名検索
- Alias検索
- 英数字の正規化
- ハイフン・空白・ドット無視
- 日本語Alias検索
- 自由入力fallback
```

---

## Out of Scope for MVP

MVPでは以下は対象外。

```text
- 色名検索
- 型番検索
- コラボ名検索
- 画像検索
- AIによる自動推定
- 外部API検索
```

---

## Future Expansion

将来的に以下を追加する。

```text
- Colorway master
- Style code master
- Collaboration master
- User submitted alias candidates
- Search analytics
```

---

## Quality Standard

ユーザーが以下の入力で3秒以内に目的候補へ到達できること。

```text
AJ1
AF1
AM95
990
NB550
GT2160
XT6
エアマックス
カヤノ
```

この基準を満たせない場合、ブランド・モデル数が多くても検索品質は不十分とみなす。
