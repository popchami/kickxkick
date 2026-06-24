# Kick×Kick Alias Master Spec v1.0

## Purpose

この仕様書は、Kick×Kick の検索で使う Alias 管理ルールを定義する。

Alias は、ユーザーが正式名称を知らなくてもブランド・モデル候補に到達するための検索補助データである。

---

## Basic Policy

Alias は検索専用であり、表示名・保存名には使わない。

例:

```text
入力: AJ1
表示: Air Jordan 1
保存: Air Jordan 1
```

---

## Why Alias Matters

ユーザーは正式名称で検索しないことが多い。

例:

```text
Air Force 1 -> AF1
Air Jordan 1 -> AJ1
Air Max 95 -> AM95
New Balance 550 -> NB550
ASICS GT-2160 -> GT2160
Salomon XT-6 -> XT6
```

候補が存在していても、Aliasで検索できなければ、ユーザーは「無い」と感じる。

---

## Alias Location

MVPでは、Alias は各モデルマスターファイル内の `Alias Candidates` に記載する。

将来的には、検索実装用に以下のような統合データへ変換する。

```text
alias -> targetBrandId + targetModelName
```

---

## Alias Types

Alias は以下に分類する。

```text
abbreviation
normalized_name
japanese
series
brand_short_name
number_only
common_typo
```

---

## Abbreviation Alias

略称。

例:

```text
AF1 -> Air Force 1
AJ1 -> Air Jordan 1
AM95 -> Air Max 95
NB550 -> New Balance 550
GT2160 -> ASICS GT-2160
XT6 -> Salomon XT-6
```

---

## Normalized Name Alias

空白・ハイフン・ドットを省略した表記。

例:

```text
Airmax95 -> Air Max 95
GT2160 -> GT-2160
Cloud5 -> Cloud 5
MB01 -> MB.01
SP110 -> SP-110
```

---

## Japanese Alias

日本語検索用のAlias。

例:

```text
エアフォース -> Air Force 1
エアマックス -> Air Max Series
ジョーダン -> Air Jordan
ニューバランス -> New Balance
カヤノ -> GEL-Kayano
ボメロ -> Zoom Vomero 5
ペガサス -> Pegasus
オニツカ -> Onitsuka Tiger
```

---

## Series Alias

シリーズ名から複数モデルへ到達するためのAlias。

例:

```text
Air Max -> Air Max Series
990 -> New Balance 990 Series
Dunk -> Dunk Series
GEL-Kayano -> GEL-Kayano Series
XT -> Salomon XT Series
```

---

## Brand Short Name Alias

ブランド略称。

例:

```text
NB -> New Balance
AJ -> Air Jordan
AF -> Air Force 1 Series
LCS -> le coq sportif
```

---

## Number Only Alias

数字だけで検索されやすいモデル。

例:

```text
550 -> New Balance 550
574 -> New Balance 574
990 -> New Balance 990 Series
1130 -> ASICS GEL-1130
1090 -> ASICS GEL-1090
2160 -> ASICS GT-2160
```

注意:

数字だけのAliasは衝突しやすいため、検索結果ではブランドTier・モデルPriorityで並び替える。

---

## Alias Collision Rule

同じAliasが複数モデルに対応する場合、1つに無理に固定しない。

例:

```text
990 -> 990v1 / 990v2 / 990v3 / 990v4 / 990v5 / 990v6
Dunk -> Dunk Low / Dunk High / SB Dunk
Air Max -> Air Max 1 / 90 / 95 / 97 / Plus
```

この場合はシリーズ候補として複数結果を返す。

---

## Do Not Use Alias For

以下はAliasに入れすぎない。

```text
- 色名だけ
- コラボ名だけ
- 店舗名だけ
- 真偽不明の俗称
- 一時的なSNS略称
```

例:

```text
NG: Panda -> Dunk Low
NG: Chicago -> Air Jordan 1
```

これらは将来の Colorway / Collaboration master で扱う。

---

## MVP Required Alias Set

MVPで最低限対応するAlias。

```text
AF1 -> Air Force 1
AJ1 -> Air Jordan 1
AJ4 -> Air Jordan 4
AM95 -> Air Max 95
AM97 -> Air Max 97
NB550 -> New Balance 550
NB574 -> New Balance 574
990 -> New Balance 990 Series
990v6 -> New Balance 990v6
GT2160 -> ASICS GT-2160
1130 -> ASICS GEL-1130
Kayano14 -> ASICS GEL-Kayano 14
XT6 -> Salomon XT-6
XT4 -> Salomon XT-4
Cloud5 -> On Cloud 5
Mexico66 -> Onitsuka Tiger Mexico 66
```

---

## Japanese MVP Alias Set

```text
エアフォース -> Air Force 1
エアマックス -> Air Max Series
ジョーダン -> Air Jordan
ニューバランス -> New Balance
カヤノ -> GEL-Kayano
ボメロ -> Zoom Vomero 5
ペガサス -> Pegasus
オニツカ -> Onitsuka Tiger
ダンク -> Dunk Series
```

---

## Alias Data Object

将来の実装では以下のような形で扱えること。

```json
{
  "alias": "AJ1",
  "normalizedAlias": "aj1",
  "targetType": "model_series",
  "brandId": "air_jordan",
  "targetName": "Air Jordan 1",
  "matchType": "alias_exact",
  "priority": 100
}
```

---

## Target Type

```text
brand
model
model_series
```

---

## Priority Rule

Aliasにも優先度を持たせる。

```text
100: 超定番Alias
90: 高頻度Alias
70: ブランドファン向けAlias
50: 補完Alias
```

---

## Audit Rule

Alias監査では以下を見る。

```text
- 略称で検索できるか
- 日本語で検索できるか
- 数字だけ検索で代表モデルに届くか
- 同じAliasが複数対象に衝突していないか
- 色名やコラボ名をAliasに入れすぎていないか
```

保留が出た場合は以下へ記録する。

```text
docs/AUDIT_TRACKER.md
```

---

## Quality Standard

以下の入力で目的候補へ到達できること。

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

Aliasが不足して検索できない場合、モデル候補が存在しないのと同じ体験になる。
