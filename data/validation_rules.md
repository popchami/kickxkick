# Kick×Kick Data Validation Rules v1.8

## Purpose

このファイルは、`data/` 配下のJSONデータを追加・更新する際の検証ルールを定義する。

目的は、ブランド・モデル・Alias・検索キーワードの品質を維持し、検索UXを壊さないことである。

---

## 0. Market Reference Rule

Kick×Kickのモデル追加は、国内ユーザーが実際に探す可能性を重視する。

追加候補の優先順位:

```text
1. ABC-MARTなど国内大手販売サイトに掲載されるブランド・モデル
2. ブランド公式サイトで正式表記を確認できるモデル
3. 公式情報ではないが、信頼できる大手販売店で複数確認できるモデル
```

### OK

```text
- ABC-MARTにブランド掲載があり、公式サイトでモデル名を確認できる
- 公式サイトの定番モデル一覧に掲載されている
- 国内流通が明確で、検索される可能性が高い
```

### NG

```text
- 色名だけ
- コラボ名だけ
- 低確度の噂モデル
- 公式表記が不明な略称だけ
- 商品画像や説明文のコピー
```

---

## 1. Canonical Name Rule

保存名・表示名は必ず `models.json` の `modelName` を使う。

Aliasや検索キーワードを保存名にしてはいけない。

### OK

```text
Air Force 1
Air Jordan 1
Air Max 95
GT-2160
P-6000
Chuck Taylor All Star
Old Skool
Club C
Ride 19
XT-6
AGILITY PEAK 6
VAPOR GLOVE 7
Ghost 18
Cascadia Elite
D'Lites
Uno
GO WALK
GO RUN
BOBS
Court & Classics
SKECHERS Street
GO GOLF
Classic Clog
Crocband Clog
Classic Bae Clog
Echo Clog
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

### NG

```text
AF1
AJ1
AM95
GT2160
P6000
ChuckTaylor
OldSkool
ClubC
Ride19
XT6
AgilityPeak6
VaporGlove7
Ghost18
CascadiaElite
DLites
GoWalk
GoRun
SkechersBOBS
CourtClassics
SkechersStreet
GoGolf
ClassicClog
CrocbandClog
ClassicBaeClog
EchoClog
DrMartens1460
DocMartens1460
DrMartens1461
DocMartens1461
DrMartens2976
DrMartensJadon
DrMartensAdrian
DrMartensGryphon
```

---

## 2. Model ID Rule

`models.json` の `id` は小文字スネークケースで統一する。

形式:

```text
{brand_id}_{model_slug}
```

### OK

```text
nike_air_max_95
new_balance_990v6
asics_gt_2160
air_jordan_1
adidas_campus_00s
puma_speedcat
vans_old_skool
reebok_club_c
saucony_ride_19
salomon_xt_6
merrell_agility_peak_6
brooks_ghost_18
skechers_d_lites
skechers_go_walk
skechers_court_classics
skechers_go_golf
crocs_classic_clog
crocs_crocband_clog
crocs_classic_bae_clog
crocs_echo_clog
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

### NG

```text
NikeAirMax95
newbalance990v6
asics_gt2160
AJ1
OldSkool
XT6
AgilityPeak6
Ghost18
GoWalk
SkechersStreet
ClassicClog
EchoClog
DrMartens1460
DocMartens1461
DrMartensJadon
```

---

## 3. Brand ID Rule

`models.json` の `brandId` は必ず `brands.json` に存在すること。

### OK

```text
brandId: nike
brandId: new_balance
brandId: asics
brandId: puma
brandId: converse
brandId: vans
brandId: reebok
brandId: saucony
brandId: salomon
brandId: merrell
brandId: brooks
brandId: skechers
brandId: crocs
brandId: dr_martens
```

### NG

```text
brandId: nb
brandId: jordan
brandId: nike_sportswear
brandId: converse_all_star
brandId: salomon_sportstyle
brandId: brooks_running
brandId: skechers_usa
brandId: crocs_japan
brandId: drmartens
brandId: docs
```

---

## 4. Alias Rule

Aliasは検索専用。

表示名・保存名には使わない。

### Aliasに入れてよいもの

```text
AF1
AJ1
AM95
P6000
GT2160
NB550
Campus00s
SL72
Kayano14
OldSkool
Sk8Hi
ClubC
Ride19
XT6
XAPro
AgilityPeak6
AgilityPeak6GTX
VaporGlove7
TrailGlove8
JungleTrekMoc
Ghost18
GhostTrail
AdrenalineGTS
CascadiaElite
RevelMax
DLites
D-Lites
SkechersUno
GoWalk
GoRun
SkechersBOBS
CourtClassics
SkechersStreet
GoGolf
ClassicClog
CrocsClassicClog
CrocbandClog
ClassicBaeClog
EchoClog
DrMartens1460
DocMartens1460
DrMartens1461
DocMartens1461
DrMartens2976
DocMartens2976
DrMartensJadon
DrMartensSinclair
DrMartensAdrian
DrMartensBlaire
DrMartensGryphon
DrMartensJorge
DrMartensCarlson
DrMartens8053
DrMartens3989
DrMartens101
DrMartensChurch
DrMartensRamsey
```

### Aliasに入れないもの

```text
Air
Max
GEL
Jordan
Nike
New Balance
Old
Classic
Star
Club
Ride
Guide
XT
Pro
Peak
Glove
Ghost
Trail
Uno
Walk
Run
BOBS
Court
Street
Golf
Clog
Bae
Echo
Docs
DMs
Boot
Shoe
Loafer
Sandal
Mule
Chelsea
Platform
Martens
Dr.Martens
Doc Martens
```

理由:

```text
広すぎるAliasは候補を増やしすぎ、サジェスト品質を落とすため。
```

---

## 5. searchKeywords Rule

searchKeywords は、モデル名・Aliasだけでは拾えない検索を補助する。

### searchKeywordsに入れてよいもの

```text
95
990
2160
1130
AirMax95
エアマックス95
カヤノ14
ジーティー2160
チャック70
オールドスクール
ポンプフューリー
ライド19
エックスティー6
アジリティピーク6
ベイパーグローブ7
ゴースト18
カスケディアエリート
ディーライツ
スケッチャーズウノ
ゴーウォーク
ゴーラン
SkechersBOBS
CourtClassics
コートクラシックス
SkechersStreet
スケッチャーズストリート
GoGolf
ゴーゴルフ
ClassicClog
クラシッククロッグ
CrocbandClog
クロックバンドクロッグ
ClassicBaeClog
クラシックベイクロッグ
EchoClog
エコークロッグ
1460
ドクターマーチン1460
1461
ドクターマーチン1461
2976
ドクターマーチン2976
DrMartensJadon
ドクターマーチンジェイドン
DrMartensSinclair
ドクターマーチンシンクレア
DrMartensAdrian
ドクターマーチンエイドリアン
DrMartensBlaire
ドクターマーチンブレア
DrMartensGryphon
ドクターマーチングリフォン
DrMartensJorge
ドクターマーチンホルヘ
DrMartensCarlson
ドクターマーチンカールソン
8053
3989
101
DrMartensChurch
DrMartensRamsey
```

### searchKeywordsに入れないもの

```text
9
1
A
Air
Max
GEL
Cloud
XT
Pro
Old
Classic
Star
Club
Ride
Guide
Peak
Glove
Ghost
Trail
Uno
Walk
Run
BOBS
Court
Street
Golf
Clog
Bae
Echo
Docs
DMs
Boot
Shoe
Loafer
Sandal
Mule
Chelsea
Platform
Martens
Dr.Martens
Doc Martens
```

理由:

```text
1文字だけの数字・英字や広すぎる単語は、不要な候補を増やすため。
```

---

## 6. Number Search Rule

数字だけで検索されやすいモデルは `search_keywords.json` に数字を入れる。

### OK

```text
95 -> Air Max 95
990 -> 990v1〜990v6
2160 -> GT-2160
1130 -> GEL-1130
550 -> 550
9060 -> 9060
1460 -> Dr.Martens 1460
1461 -> Dr.Martens 1461
2976 -> Dr.Martens 2976
8053 -> Dr.Martens 8053
3989 -> Dr.Martens 3989
101 -> Dr.Martens 101
```

### NG

```text
1
4
6
7
8
9
```

---

## 7. Staging Rule

本体JSONが1行圧縮形式で安全に差分追記できない場合は、検証済みデータを `data/staging_*.json` に分離してよい。

### OK

```text
- ブランドIDが既にbrands.jsonに存在する
- modelId / alias / searchKeyword の対応が明確
- 本体JSON反映前であることを明記する
- CHANGELOG / README / Coverage / Task Board に状態を反映する
```

### NG

```text
- ステージングを本体反映済みとして扱う
- app/assets/data 側と同期済みと誤記する
- 未検証モデルをまとめて投入する
```

## Dr.Martens v0.5.7 audit rule

- Accept model-specific forms such as `DrMartens1460` and `ドクターマーチン1460`.
- Reject broad standalone terms including `Docs`, `DMs`, `Boot`, `Shoe`, `Loafer`, `Sandal`, `Mule`, `Chelsea`, `Platform`, and `Martens`.
- Require every Alias/searchKeyword modelId to resolve to a model in `models.json`.


## v0.5.8 SKECHERS audit

- Full distinctive family names are allowed.
- Standalone generic words such as Walk, Run, Sport, Street, Golf, Comfort, Cushion, Arch and Flex are blocked.
- Summits, Equalizer and Reggae are only allowed with the SKECHERS brand in Alias/searchKeywords.

## v0.5.9追加監査

- staging内のAlias/searchKeywordsが禁止広義語と完全一致した場合は同期を失敗させる
- 全Alias/searchKeywordsのmodelIdがmodels.jsonに存在すること
- model IDは全体で一意であること
- `data/*.json`と`app/assets/data/*.json`はバイト一致すること


## Timberland v0.6.0 audit
Standalone category, feature, position and brand terms are rejected. Full canonical names and brand-qualified Japanese phrases are allowed.

## FILA v0.6.1 audit
Standalone brand, person-name fragments, category and generic product terms are rejected. Full canonical names and brand-qualified Japanese phrases are allowed.
