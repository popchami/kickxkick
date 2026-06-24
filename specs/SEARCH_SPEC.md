# Kick×Kick Search Spec v1.0

## Purpose

この仕様書は、Kick×Kick の検索挙動を定義する。

`SEARCH_DATA_SPEC.md` が検索データ構造を定義するのに対し、この仕様書ではユーザー入力に対してどのように候補を返すかを定義する。

---

## Search Goal

ユーザーが正式名称を知らなくても、ブランド・モデル候補に到達できること。

重要な入力例:

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

---

## Search Scope

MVPで検索する対象は以下。

```text
Brand name
Model name
Alias
Series
```

MVPでは以下は検索対象外。

```text
Colorway
Style code
Collaboration name
Release year
Shop name
Market price
```

---

## Search Flow

ユーザー入力に対して以下の順で処理する。

```text
1. 入力値を正規化する
2. 完全一致を探す
3. Alias完全一致を探す
4. 前方一致を探す
5. 部分一致を探す
6. シリーズ一致を探す
7. 結果をランキングする
8. 見つからなければ自由入力を提示する
```

---

## Normalization

検索前に、入力値と検索対象を正規化する。

正規化ルール:

```text
- 大文字小文字を無視
- 半角全角を可能な範囲で同一扱い
- 空白を無視
- ハイフンを無視
- ドットを無視
- アポストロフィを無視
- 日本語表記はAliasで補完
```

例:

```text
GT2160 -> GT-2160
Airmax95 -> Air Max 95
NB 550 -> NB550
Cloud5 -> Cloud 5
AF-1 -> AF1
MB.01 -> MB01
```

---

## Match Types

検索結果には一致タイプを持たせる。

```text
exact
alias_exact
prefix
contains
series
normalized
```

優先順位:

```text
1. exact
2. alias_exact
3. prefix
4. series
5. contains
6. normalized
```

---

## Exact Match

正式名称と完全一致した場合。

例:

```text
入力: Air Max 95
結果: Nike Air Max 95
```

---

## Alias Exact Match

Aliasと完全一致した場合。

例:

```text
入力: AJ1
結果: Air Jordan 1

入力: NB550
結果: New Balance 550
```

表示は必ず正式名称にする。

---

## Prefix Match

正式名称またはAliasが入力値で始まる場合。

例:

```text
入力: Air Max
結果:
- Nike Air Max 1
- Nike Air Max 90
- Nike Air Max 95
- Nike Air Max 97
```

---

## Contains Match

正式名称またはAliasの一部に入力値を含む場合。

例:

```text
入力: 990
結果:
- New Balance 990v6
- New Balance 990v5
- New Balance 990v4
- New Balance 990v3
- New Balance 990v2
- New Balance 990v1
```

---

## Series Match

シリーズ名に一致した場合、シリーズ内の代表モデルを出す。

例:

```text
入力: Air Max
結果:
- Nike Air Max 1
- Nike Air Max 90
- Nike Air Max 95
- Nike Air Max 97
- Nike Air Max Plus
```

```text
入力: 990
結果:
- New Balance 990v6
- New Balance 990v5
- New Balance 990v4
- New Balance 990v3
- New Balance 990v2
- New Balance 990v1
```

---

## Japanese Alias Search

日本語入力はAliasで対応する。

必須例:

```text
エアフォース -> Air Force 1
エアマックス -> Air Max Series
ジョーダン -> Air Jordan
カヤノ -> GEL-Kayano
ボメロ -> Zoom Vomero 5
ペガサス -> Pegasus
ニューバランス -> New Balance
オニツカ -> Onitsuka Tiger
```

日本語AliasはMVPで最低限対応する。

---

## Brand Search

ブランド名だけでも検索できる。

例:

```text
入力: Nike
結果:
- Nike ブランド候補
- Nike の代表モデル
```

ブランド候補はモデル候補より上に出してよい。

---

## Brand + Model Search

ブランド名とモデル名を一緒に入力した場合、該当ブランド内のモデルを優先する。

例:

```text
入力: Nike 95
結果:
- Nike Air Max 95
```

```text
入力: NB 550
結果:
- New Balance 550
```

---

## Ranking Rule

検索結果は以下の順で並べる。

```text
1. matchType の優先度
2. model priority
3. brand tier
4. 完全一致に近いもの
5. 短い displayName
6. アルファベット順
```

---

## Priority Examples

重要モデルは上位に出す。

例:

```text
Air Force 1: 100
Air Jordan 1: 100
Air Max 95: 95
New Balance 990v6: 95
ASICS GEL-Kayano 14: 90
Salomon XT-6: 90
Karhu Fusion 2.0: 70
```

---

## No Result Behavior

候補が見つからない場合、登録を止めない。

表示:

```text
候補が見つかりません
自由入力で登録できます
```

ボタン例:

```text
この内容で登録する
```

---

## Free Input Behavior

自由入力の場合、候補マスターには存在しないが登録は可能にする。

保存時の source:

```text
user_input
```

---

## Result Limit

MVPでは検索候補の表示上限を以下にする。

```text
ブランド候補: 最大5件
モデル候補: 最大20件
```

候補が多すぎる場合は、優先度と一致度で絞る。

---

## Minimum MVP Test Queries

MVP検索は、最低限以下を通過すること。

```text
AF1 -> Nike Air Force 1
AJ1 -> Air Jordan 1
AM95 -> Nike Air Max 95
990 -> New Balance 990 Series
NB550 -> New Balance 550
GT2160 -> ASICS GT-2160
XT6 -> Salomon XT-6
エアマックス -> Nike Air Max Series
カヤノ -> ASICS GEL-Kayano Series
ボメロ -> Nike Zoom Vomero 5
```

---

## Quality Standard

検索品質の合格基準:

```text
主要な略称・日本語名で検索して、3秒以内に目的候補へ到達できること。
```

検索で見つからない状態は、候補が存在しないのと同じ体験になる。

そのため、モデル数を増やすだけでなく、検索で到達できることを重視する。
