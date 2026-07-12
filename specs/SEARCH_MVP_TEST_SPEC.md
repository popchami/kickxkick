# Kick×Kick Search MVP Test Spec v1.1

## Purpose

この仕様書は、Kick×Kick の検索MVPが最低限満たすべきテストケースを定義する。

検索品質は、ブランド数・モデル数と同じくらいユーザー満足度に影響する。

候補が存在していても、検索で到達できなければユーザーには「無い」と感じられるため、MVP段階で必ず確認する。

---

## v1.1 での変更点（2026-07-12 現行実装との突合レビューより）

現行実装（`app/lib/features/search/`）とテストケースを突合した結果、以下を反映した。

```text
1. 現行検索は「ブランド選択 → 選択ブランド内でモデル/Alias/キーワード検索」の
   2段階UXであることを明記し、各テストケースに前提条件を追記した。
2. ブランド単位のAlias/略称/日本語名（BS-002, BS-003, BS-004）は現状未実装と判明。
   「MVP改善候補（未実装）」セクションへ分離した（削除はしていない）。
3. ブランド+モデルの結合1クエリ（BM-001〜003）、および
   モデル単体を超えるライン/集約結果を期待するケース
   （Series集約: JA-002, JA-004, JA-006／ブランド・ラインレベル結果: JA-003）は、
   対応するデータ・実装が現行に存在しないため、「将来機能（MVP合否対象外）」
   セクションへ分離した（削除はしていない）。
4. Regression Rule から、上記3.に該当する項目（エアマックス、カヤノ）を除外し、
   代わりにMVP対象内の項目に差し替えた。
```

コード・データ・依存関係の変更は行っていない。本ファイルのみの整理。

---

## Related Specs

```text
specs/SEARCH_SPEC.md
specs/SEARCH_DATA_SPEC.md
specs/ALIAS_MASTER_SPEC.md
specs/REGISTRATION_FLOW_SPEC.md
specs/BRAND_MASTER.md
specs/MODEL_MASTER/README.md
```

---

## テスト実施上の前提（v1.1で追加）

現行実装は2段階UX（`SneakerMasterPicker`想定）:

```text
1. ブランド検索（自由文字列 → ブランド候補。suggestBrands相当）
2. モデル検索（選択済みブランドID + 自由文字列 → モデル/Alias/キーワード候補。suggestModels相当）
```

以下の「Model Search Tests」「Alias Search Tests」「Japanese Alias Tests（一部）」
「Normalization Tests」「Series Search Tests」は、**入力欄に記載の文字列を打つ前に、
期待結果に対応するブランドが1.の手順で選択済みであること**を前提とする。
（例: MS-001は「Nikeを選択済みの状態で `Air Force 1` と入力する」テストとして読む）

---

## Pass Condition

以下を満たしたらMVP検索は合格とする。

```text
1. 主要ブランドが検索できる
2. ブランド選択後、主要モデルが検索できる
3. ブランド選択後、Aliasで検索できる
4. ブランド選択後、日本語Aliasで検索できる（個別モデル名に対応するもの）
5. 空白・ハイフン・ドット違いを吸収できる
6. 候補が無い場合も自由入力へ進める
```

---

## Brand Search Tests

### BS-001

入力:

```text
Nike
```

期待結果:

```text
Nike
```

---

以下、BS-002〜BS-004（ブランド単位Alias/日本語名）は現状未実装と判明したため、
「MVP改善候補（未実装）」セクションへ移動した。旧テストID・内容は移動先を参照。

---

## Model Search Tests

前提: 各ケースに対応するブランドを選択済みとする。

### MS-001

前提ブランド: Nike

入力:

```text
Air Force 1
```

期待結果:

```text
Nike Air Force 1
```

### MS-002

前提ブランド: Nike

入力:

```text
Air Max 95
```

期待結果:

```text
Nike Air Max 95
```

### MS-003

前提ブランド: New Balance

入力:

```text
990v6
```

期待結果:

```text
New Balance 990v6
```

### MS-004

前提ブランド: ASICS

入力:

```text
GT-2160
```

期待結果:

```text
ASICS GT-2160
```

### MS-005

前提ブランド: Salomon

入力:

```text
XT-6
```

期待結果:

```text
Salomon XT-6
```

---

## Alias Search Tests

前提: 各ケースに対応するブランドを選択済みとする。

### AS-001

前提ブランド: Nike

入力:

```text
AF1
```

期待結果:

```text
Nike Air Force 1
```

### AS-002

前提ブランド: Nike（Air Jordan）

入力:

```text
AJ1
```

期待結果:

```text
Air Jordan 1
```

### AS-003

前提ブランド: Nike

入力:

```text
AM95
```

期待結果:

```text
Nike Air Max 95
```

### AS-004

前提ブランド: New Balance

入力:

```text
NB550
```

期待結果:

```text
New Balance 550
```

### AS-005

前提ブランド: ASICS

入力:

```text
GT2160
```

期待結果:

```text
ASICS GT-2160
```

### AS-006

前提ブランド: Salomon

入力:

```text
XT6
```

期待結果:

```text
Salomon XT-6
```

### AS-007

前提ブランド: Onitsuka Tiger

入力:

```text
Mexico66
```

期待結果:

```text
Onitsuka Tiger Mexico 66
```

---

## Japanese Alias Tests

前提: 各ケースに対応するブランドを選択済みとする。
JA-002, JA-003, JA-004, JA-006 は「将来機能（MVP合否対象外）」セクションへ移動済み。

### JA-001

前提ブランド: Nike

入力:

```text
エアフォース
```

期待結果:

```text
Nike Air Force 1
```

### JA-005

前提ブランド: Nike

入力:

```text
ボメロ
```

期待結果:

```text
Nike Zoom Vomero 5
```

---

## Normalization Tests

前提: 各ケースに対応するブランドを選択済みとする。

### NT-001

前提ブランド: Nike

入力:

```text
AF-1
```

期待結果:

```text
Nike Air Force 1
```

### NT-002

前提ブランド: Nike

入力:

```text
Airmax95
```

期待結果:

```text
Nike Air Max 95
```

### NT-003

前提ブランド: New Balance

入力:

```text
NB 550
```

期待結果:

```text
New Balance 550
```

### NT-004

前提ブランド: PUMA

入力:

```text
MB01
```

期待結果:

```text
PUMA MB.01
```

### NT-005

前提ブランド: SPINGLE

入力:

```text
SP110
```

期待結果:

```text
SPINGLE SP-110
```

---

## Series Search Tests

前提: 各ケースに対応するブランドを選択済みとする。
（ここでの「Series」は、個々のモデル名が同じプレフィックスで始まる複数件ヒットを指す。
「将来機能」セクションの仮想的な集約エンティティとしての「Series」とは別物）

### SS-001

前提ブランド: New Balance

入力:

```text
990
```

期待結果:

```text
New Balance 990v6
New Balance 990v5
New Balance 990v4
New Balance 990v3
New Balance 990v2
New Balance 990v1
```

### SS-002

前提ブランド: Nike

入力:

```text
Air Max
```

期待結果:

```text
Nike Air Max 1
Nike Air Max 90
Nike Air Max 95
Nike Air Max 97
Nike Air Max Plus
```

### SS-003

前提ブランド: Nike

入力:

```text
Dunk
```

期待結果:

```text
Nike Dunk Low
Nike Dunk High
Nike SB Dunk Low
```

---

## No Result Tests

### NR-001

前提: ブランド検索ステップ

入力:

```text
Unknown Brand
```

期待結果:

```text
候補が見つかりません
自由入力で登録できます
```

### NR-002

前提ブランド: 任意（例: Nike）を選択済み

入力:

```text
Unknown Model
```

期待結果:

```text
候補が見つかりません
自由入力で登録できます
```

---

## MVP改善候補（未実装）

現行実装ではブランド単位のAlias/略称/日本語名の仕組みが存在しない
（`BrandMaster`は`brandId`/`brandName`/`tier`/`isEnabled`のみで、
`ModelAliasMaster`/`SearchKeywordMaster`はmodelId単位のみ）。
実装するかどうかは製品判断待ち。

### BS-002（旧）

入力:

```text
NB
```

期待結果:

```text
New Balance
```

### BS-003（旧）

入力:

```text
ニューバランス
```

期待結果:

```text
New Balance
```

### BS-004（旧）

入力:

```text
オニツカ
```

期待結果:

```text
Onitsuka Tiger
```

---

## 将来機能（MVP合否対象外）

以下は、現行のデータ・実装のどちらにも対応する仕組みが存在しないため、
MVPの合否判定から分離した。実装するかどうかは製品判断待ち。

### ブランド+モデル結合クエリ（パーサー未実装）

`suggestModels`は`brandId`を別引数として要求する2段階APIであり、
1つの自由文字列からブランドとモデルを同時に解決する経路が存在しない。

#### BM-001（旧）

入力:

```text
Nike 95
```

期待結果:

```text
Nike Air Max 95
```

#### BM-002（旧）

入力:

```text
NB 990
```

期待結果:

```text
New Balance 990 Series
```

#### BM-003（旧）

入力:

```text
ASICS 1130
```

期待結果:

```text
ASICS GEL-1130
```

### モデル以外の集約・ライン結果（データ・実装ともに未対応）

期待結果が個別モデル（`SneakerModelMaster`1件）ではなく、複数モデルをまとめた
集約・ライン単位の結果になっているケース。`suggestModels`は個々のモデルしか返さない。
以下の2種類は期待値の性質が異なるため区別する。

#### Series集約（期待値が「〜Series」という名称）

`models.json`にSeriesを含むmodelNameのエントリは存在しない。

##### JA-002（旧）

前提ブランド: Nike

入力:

```text
エアマックス
```

期待結果（現行データに存在しない集約名）:

```text
Nike Air Max Series
```

##### JA-004（旧）

前提ブランド: ASICS

入力:

```text
カヤノ
```

期待結果（現行データに存在しない集約名）:

```text
ASICS GEL-Kayano Series
```

##### JA-006（旧）

前提ブランド: Nike

入力:

```text
ダンク
```

期待結果（現行データに存在しない集約名）:

```text
Nike Dunk Series
```

#### ブランド・ラインレベル結果（Series表記ではない）

期待値はSeriesという名称ではなく、Air Jordanという1つのブランド/ライン名そのもの。
現行の`suggestModels`はモデル単位の結果しか返せないため、
そもそもこの粒度の結果を返す経路が存在しない（Series集約とは別種の非対応ケース）。

##### JA-003（旧）

前提ブランド: Nike（Air Jordan）

入力:

```text
ジョーダン
```

期待結果（現行APIでは返せない粒度）:

```text
Air Jordan
```

---

## Regression Rule

検索仕様を変更した場合、最低限このテストセットを再確認する。

特に以下は必ず落としてはいけない（MVP合否対象内のみ）。

```text
AF1
AJ1
AM95
990
NB550
GT2160
XT6
エアフォース
ボメロ
自由入力fallback
```

（v1.0からの変更: エアマックス・カヤノは「将来機能」セクションへ移動したため、
このリストからは除外し、代わりにエアフォース・ボメロ（MVP対象内の日本語Alias）を追加した）

---

## Notes

MVPでは自動テスト化できなくてもよい。

ただし、実装後に手動確認できるチェックリストとして必ず使う。

この環境（proot-distro、Flutter/Dart SDK未インストール）ではアプリ実行による実機検証ができないため、
2026-07-12時点でのMVP対象内テストケースは、コードとデータの静的突合による確認までにとどまる。
実機検証は別途、Flutter/Dartが利用可能な環境で実施すること。
