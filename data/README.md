# Kick×Kick Data Master

## Purpose

このディレクトリは、Kick×Kick がアプリ内検索・登録補助で使用する実データを管理する。

`specs/` は人が読む仕様書、`data/` は Flutter が読み込む実データ資産として扱う。

---

## Files

```text
brands.json
models.json
aliases.json
search_keywords.json
```

---

## Current Coverage

```text
Tier S: Nike / Air Jordan / adidas / New Balance / ASICS
Tier A: PUMA / Converse / Vans / Reebok
Tier B: HOKA / Saucony / SALOMON / MERRELL / BROOKS
Tier C: brand-only registry + SKECHERS model-started
```

Tier SはMVP基準でPASS。ただしABC-MARTなど国内流通リファレンスとの差分監査は継続する。

Tier Aは代表モデルのみ高確度で追加済み。今後も国内流通モデルを基準に段階拡張する。

Tier BはHOKA / Saucony / SALOMON / MERRELL / BROOKSを追加済み。MERRELL / BROOKSは v0.5.1 でモデル・Alias・searchKeywordsまで追加した。

Tier Cはブランド名を先行登録済み。v0.5.3 で SKECHERS の公式Collections確認済みモデルを8件まで拡張した。

2026-07-03時点で `data/models.json` / `data/aliases.json` / `data/search_keywords.json` と `app/assets/data/` 側は v0.5.3 として同期済み。

---

## External Reference Policy

Kick×Kickのモデルデータは、国内ユーザーが実際に探す可能性を重視する。

基本方針:

```text
1. ABC-MARTなど国内大手販売サイトをリファレンスとして見る
2. 国内流通ブランド・モデルを追加候補にする
3. モデル名はブランド公式サイトまたは信頼できる公式情報で確認する
4. 低確度モデル、色名、コラボ名だけのデータは追加しない
5. Alias / searchKeywords は検索品質を壊さない範囲に限定する
```

ABC-MARTを「完成形に近い国内流通リファレンス」として扱う。ただし商品説明文・画像・在庫情報はコピーしない。

---

## File Roles

### brands.json

ブランド実データ。

```text
brandId
brandName
tier
isEnabled
```

### models.json

モデル実データ。

```text
id
brandId
modelName
category
source
```

`modelName` は表示・保存に使う正式表記。

### aliases.json

Alias実データ。

```text
modelId
alias
```

Aliasは検索専用。表示・保存には使わない。

### search_keywords.json

検索キーワード実データ。

```text
modelId
keyword
```

数字検索、日本語検索、連結表記検索を補助する。

---

## Canonical Name Rule

保存名は必ず `models.json` の `modelName` を使う。

例:

```text
GT2160 -> GT-2160
P6000 -> P-6000
AF1 -> Air Force 1
AJ1 -> Air Jordan 1
OldSkool -> Old Skool
ClubC -> Club C
Bondi9 -> Bondi 9
Ride19 -> Ride 19
XT6 -> XT-6
AgilityPeak6 -> AGILITY PEAK 6
VaporGlove7 -> VAPOR GLOVE 7
Ghost18 -> Ghost 18
CascadiaElite -> Cascadia Elite
DLites -> D'Lites
GoWalk -> GO WALK
GoRun -> GO RUN
SkechersBOBS -> BOBS
CourtClassics -> Court & Classics
SkechersStreet -> SKECHERS Street
GoGolf -> GO GOLF
```

`aliases.json` や `search_keywords.json` の値を保存名にしてはいけない。

---

## ID Rule

`models.json` の `id` は小文字スネークケースにする。

形式:

```text
{brand_id}_{model_slug}
```

例:

```text
nike_air_max_95
new_balance_990v6
asics_gt_2160
air_jordan_1
adidas_campus_00s
puma_speedcat
vans_old_skool
reebok_club_c
hoka_bondi_9
saucony_ride_19
salomon_xt_6
merrell_agility_peak_6
brooks_ghost_18
skechers_d_lites
skechers_go_walk
skechers_court_classics
skechers_go_golf
```

---

## Alias Rule

Aliasに入れてよいもの:

```text
- よく使われる略称
- ハイフンなし表記
- スペースなし表記
- 型番の省略表記
- ブランド名と組み合わせた安全な補助表記
```

Aliasに入れないもの:

```text
- 保存名として使うべき正式名称の別表記
- 広すぎるシリーズ名だけの値
- 色名だけ
- コラボ名だけ
```

---

## Search Keyword Rule

searchKeywordsに入れてよいもの:

```text
- モデル名の途中にある数字
- 連結表記
- 日本語表記
- Aliasとは別に補助したい検索語
```

searchKeywordsに入れないもの:

```text
- 1文字だけの数字や英字
- Air / Max / GEL / Cloud / XT / Pro など広すぎる単語
- Old / Classic / Star / Club / Ride / Guide / Ghost / Trail / Glove / Peak / Uno / Street / Golf など広すぎる単語
- 色名だけ
- コラボ名だけ
```
