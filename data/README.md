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
staging_dr_martens_v0.5.5.json
sync_dr_martens_v0.5.7.py
staging_skechers_v0.5.8.json
sync_skechers_v0.5.8.py
```

---

## Current Coverage

```text
Tier S: Nike / Air Jordan / adidas / New Balance / ASICS
Tier A: PUMA / Converse / Vans / Reebok
Tier B: HOKA / Saucony / SALOMON / MERRELL / BROOKS
Tier C: brand-only registry + SKECHERS 16 models + crocs model-started + Dr.Martens 15 models
```

Tier SはMVP基準でPASS。ただしABC-MARTなど国内流通リファレンスとの差分監査は継続する。

Tier Aは代表モデルのみ高確度で追加済み。今後も国内流通モデルを基準に段階拡張する。

Tier BはHOKA / Saucony / SALOMON / MERRELL / BROOKSを追加済み。MERRELL / BROOKSは v0.5.1 でモデル・Alias・searchKeywordsまで追加した。

Tier Cはブランド名を先行登録済み。v0.5.8 で SKECHERS を16件まで拡張し、v0.5.4 で crocs の高確度クロッグモデル4件を追加した。

Dr.Martensは v0.5.7-merge-ready-audited として `staging_dr_martens_v0.5.5.json` に15モデルの検証済みデータを分離している。同期用の `data/sync_dr_martens_v0.5.7.py` は作成済み。本体JSONが1行圧縮形式のため、壊さないようにリポジトリ実行環境で同期スクリプトを実行して `models.json` / `aliases.json` / `search_keywords.json` と `app/assets/data/` 側へ反映する。

2026-07-09時点で `data/models.json` / `data/aliases.json` / `data/search_keywords.json` と `app/assets/data/` 側は v0.5.4 として同期済み。Dr.Martens拡張分はmerge-ready auditedだが、まだ本体JSON未反映。

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

### staging_dr_martens_v0.5.5.json

Dr.Martensの検証済み追加候補。

```text
1460
1461
2976
Jadon
Sinclair
Adrian
Blaire
Gryphon
Jorge
Carlson
8053
3989
101
Church
Ramsey
```

本体JSONへ直接反映する前の安全なステージングデータとして扱う。

### sync_dr_martens_v0.5.7.py
staging_skechers_v0.5.8.json
sync_skechers_v0.5.8.py

Dr.Martens staging を本体JSONと `app/assets/data/` に同期するための決定的スクリプト。

```text
python3 data/sync_dr_martens_v0.5.7.py
staging_skechers_v0.5.8.json
sync_skechers_v0.5.8.py
```

手作業で圧縮JSONを編集せず、このスクリプトで同時反映する。

---

## Canonical Name Rule

保存名は必ず `models.json` の `modelName` を使う。

例:

```text
AF1 -> Air Force 1
AJ1 -> Air Jordan 1
GT2160 -> GT-2160
OldSkool -> Old Skool
ClubC -> Club C
Bondi9 -> Bondi 9
Ride19 -> Ride 19
XT6 -> XT-6
AgilityPeak6 -> AGILITY PEAK 6
Ghost18 -> Ghost 18
DLites -> D'Lites
GoWalk -> GO WALK
ClassicClog -> Classic Clog
CrocbandClog -> Crocband Clog
ClassicBaeClog -> Classic Bae Clog
EchoClog -> Echo Clog
DrMartens1460 -> 1460
DrMartens1461 -> 1461
DrMartens2976 -> 2976
DrMartensJadon -> Jadon
DrMartensAdrian -> Adrian
DrMartensGryphon -> Gryphon
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
hoka_bondi_9
saucony_ride_19
salomon_xt_6
merrell_agility_peak_6
brooks_ghost_18
skechers_d_lites
crocs_classic_clog
dr_martens_1460
dr_martens_1461
dr_martens_2976
dr_martens_jadon
dr_martens_sinclair
dr_martens_adrian
dr_martens_blaire
dr_martens_gryphon
dr_martens_jorge
dr_martens_carlson
dr_martens_8053
dr_martens_3989
dr_martens_101
dr_martens_church
dr_martens_ramsey
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
- Old / Classic / Star / Club / Ride / Guide / Ghost / Trail / Glove / Peak / Uno / Street / Golf / Clog / Bae / Echo / Boot / Shoe / Loafer / Sandal / Mule / Chelsea / Platform / Martens など広すぎる単語
- 色名だけ
- コラボ名だけ
```

## v0.5.7 Dr.Martens sync (2026-07-10)

- 15 high-confidence Dr.Martens models were merged into the root masters.
- `models.json`, `aliases.json`, and `search_keywords.json` are mirrored to `app/assets/data/`.
- Broad standalone category or nickname terms remain excluded.


## v0.5.8 SKECHERS sync (2026-07-11)

- 8 high-confidence SKECHERS families were added, bringing coverage to 16 entries.
- Root JSON and app assets are synchronized deterministically.
- Generic standalone terms remain excluded.

## v0.5.9 crocs同期

- crocs: 10モデル（既存4 + 追加6）
- root JSONと`app/assets/data`は同一内容で同期する
- Alias/searchKeywordsはモデル固有の複合語のみ採用し、広すぎる単独語は除外する
- 同期: `python3 data/sync_crocs_v0.5.9.py`


## v0.6.0 Timberland
- 6 high-confidence models added and mirrored to app assets.
- Model-specific aliases and Japanese full-name search keywords only.
- Broad standalone terms such as Boot, Waterproof, Motion and Timberland are blocked.

## v0.6.1 FILA
- 6 high-confidence models added and mirrored to app assets.
- Only brand-qualified aliases and full-name Japanese search keywords were added.
- Broad standalone terms such as FILA, Original, Fitness, Grant and Hill are blocked.

## v0.6.2 Danner
- 6 high-confidence models added and mirrored to app assets.
- Only brand-qualified aliases and full-name Japanese search keywords were added.
- Broad standalone terms such as Danner, Light, Field, Trail, Boot and Waterproof are blocked.

## v0.6.3 RED WING
- 6 high-confidence model families were added and mirrored to app assets.
- Official Japanese catalog naming was used; color, leather and style-number variants were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as RED WING, Classic, Moc, Iron, Ranger, Postman, Oxford, Chelsea and Boot are blocked.

## v0.6.4 HAWKINS
- 8 high-confidence product families were confirmed against ABC-MART official product pages and mirrored to app assets.
- Colors, sizes and manufacturer-number revisions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as HAWKINS, Boot, Shoe, Sneaker, Sandal, Waterproof and partial model-name fragments are blocked.

## v0.6.5 BIRKENSTOCK
- 12 high-confidence model families were confirmed against the official BIRKENSTOCK Japan catalog and mirrored to app assets.
- Colors, materials, widths, EVA editions and soft-footbed editions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as BIRKENSTOCK, model-family names, Sandal, Clog, EVA, Leather and Suede are blocked.

## v0.6.6 CLARKS
- Eight high-confidence model families were confirmed against the official CLARKS Japan catalog and mirrored to app assets.
- Colors, materials, gender and seasonal editions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as CLARKS, Wallabee, Boot, Desert, Trek, Torhill and GTX are blocked.
