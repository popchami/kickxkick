# Kick×Kick Model Master Guide

## Purpose

このディレクトリは、Kick×Kick のブランド別モデル候補を管理する場所である。

目的は、ユーザーがスニーカー登録時に「自分のブランド・モデルが候補にある」と感じられる状態を作ること。

完全網羅ではなく、主要モデルを高品質に揃え、候補にない場合も自由入力できる設計を維持する。

---

## File Location Rule

ブランドごとのモデルマスターは以下に置く。

```text
specs/MODEL_MASTER/{BRAND_FILE_NAME}.md
```

例:

```text
specs/MODEL_MASTER/NIKE.md
specs/MODEL_MASTER/AIR_JORDAN.md
specs/MODEL_MASTER/ADIDAS.md
```

---

## Brand File Naming Rule

ファイル名は英大文字のスネークケースを基本にする。

```text
NEW_BALANCE.md
ONITSUKA_TIGER.md
LE_COQ_SPORTIF.md
DR_MARTENS.md
```

記号やスペースは避ける。

---

## Minimum Content Rule

各ブランドファイルには最低限以下を入れる。

```md
# Kick×Kick Model Master: BrandName v1.x

## Purpose

## Brand

## Main Models

## Alias Candidates

## Notes
```

ブランドによって必要なら以下を追加する。

```md
## Running
## Basketball
## Lifestyle
## Outdoor
## Skateboarding
## Heritage
## Premium Series
```

---

## Model Addition Rule

モデル追加時は、以下を優先する。

1. 登録頻度が高い定番モデル
2. ブランドファンが当然あると思うモデル
3. 現行人気モデル
4. 復刻・アーカイブ系の有名モデル
5. コラボ名ではなくベースモデル

原則として、色名・型番・限定名はモデルマスターに入れない。

例:

```text
OK: Air Max 95
NG: Air Max 95 Neon Yellow 2020
```

色名や型番は将来の別マスターで扱う。

---

## Alias Rule

Alias Candidates には、ユーザーが検索しそうな表記ゆれを入れる。

例:

```text
AF1 -> Air Force 1
AM95 -> Air Max 95
AJ1 -> Air Jordan 1
NB550 -> 550
GT2160 -> GT-2160
```

日本語検索が想定される場合は日本語も入れてよい。

例:

```text
エアフォース -> Air Force 1
エアマックス -> Air Max
ボメロ -> Zoom Vomero 5
```

---

## Audit Rule

監査時は以下を見る。

- 代表モデルが不足していないか
- 誤字がないか
- リスト記法が壊れていないか
- 古いメモが残っていないか
- Alias が不足していないか
- ユーザーが検索しそうな名称で見つかるか

監査後はファイルのバージョンを上げる。

例:

```text
v1.0 -> v1.1
```

---

## Audit Tracker Rule

保留・ブロック・再確認対象は必ず以下へ記録する。

```text
docs/AUDIT_TRACKER.md
```

チャット上だけで管理しない。

状態は以下を使う。

```text
OPEN
IN_PROGRESS
DONE
BLOCKED
```

---

## Quality Standard

ブランド追加は、ブランド名を追加しただけでは完了としない。

最低限、以下を満たすこと。

- 代表モデルが入っている
- 検索されやすい別名がある
- そのブランドのユーザーが見て大きな違和感がない
- 自由入力 fallback を前提にしている

---

## Free Input Policy

Kick×Kick は、すべてのブランド・モデルを完全網羅することを目的にしない。

必ず自由入力できる仕様を維持する。

理由:

- 限定モデルが多い
- 地域限定がある
- コラボが多い
- 型番違いが多い
- ユーザー所有品が候補にない可能性がある

候補は入力補助であり、登録を制限するものではない。

---

## Do Not Include

モデルマスターには以下を原則入れない。

- ブランドロゴ
- 商標画像
- 商品画像
- 色名だけの候補
- 型番だけの候補
- コラボ名だけの候補
- 真偽確認できない噂モデル

---

## Review Priority

監査優先度は以下。

1. Tier S ブランド
2. 登録頻度が高い Tier A / B ブランド
3. 日本ユーザー向けブランド
4. コレクター向けブランド
5. ライフスタイル・補完ブランド

Tier 管理は以下を見る。

```text
specs/BRAND_MASTER.md
```

---

## Current Operation Rule

今後の作業では、以下を必ず守る。

1. GitHub上の実ファイルを読む
2. 既存内容を壊さず監査する
3. 必要なモデルだけ追加する
4. 誤記を直す
5. 保留が出たら AUDIT_TRACKER に残す
6. 更新後に再チェックする
