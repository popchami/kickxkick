# Kick×Kick AI Data Factory v1.0

## Purpose

Kick×Kick AI Data Factory は、スニーカーマスターデータを AI が育て、人間が承認するための運用設計である。

目的は、スマホ中心の開発でも、ブランド・モデル・Alias・searchKeywords を継続的に高純度で追加・監査できる状態を作ることである。

---

## Goal

最終形:

```text
AI
↓
候補作成
↓
JSON更新案
↓
Validation
↓
Audit
↓
Pull Request作成
↓
User Approve
↓
Merge
```

ユーザーはデータ入力係ではなく、編集長として承認・方向性判断を行う。

---

## Scope

AI Data Factory が扱う対象:

```text
data/brands.json
data/models.json
data/aliases.json
data/search_keywords.json
data/CHANGELOG.md
specs/MODEL_MASTER_COVERAGE.md
specs/KICKXKICK_TASK_BOARD.md
docs/AUDIT_TRACKER.md
```

---

## Core Principle

```text
Tierは重要度を表す。
品質を表すものではない。
```

すべてのTierで以下を満たすこと。

```text
Canonical Name: PASS
Alias: PASS
searchKeywords: PASS
Schema: PASS
Validation: PASS
Audit: PASS
```

---

## Data Purity Rule

AIは低確度のデータを追加しない。

禁止:

```text
- 不確かなモデル名
- 広すぎるAlias
- 広すぎるsearchKeywords
- ブランドとモデルの関係が曖昧なデータ
- コラボ名だけのモデル登録
- 色名だけのモデル登録
```

追加してよいもの:

```text
- 代表モデル
- 定番モデル
- 型番検索されやすいモデル
- 明確なAlias
- 正式表記に変換できる表記ゆれ
```

---

## Human Approval Rule

AIが直接mainへ反映し続ける運用にはしない。

原則:

```text
AI creates proposal
Human approves
Then merge
```

理由:

```text
データ品質を保つため
誤登録を防ぐため
ユーザーが編集長として最終判断するため
```

---

## Phases

### Phase 1: Manual Assisted

現在の段階。

```text
ChatGPTが候補を作る
ユーザーが承認する
ChatGPTがGitHubへ反映する
```

### Phase 2: Scheduled Proposal

次の段階。

```text
GitHub Actions または外部実行環境が定期実行
AIが候補を作る
候補ファイルを生成する
監査結果を出す
```

### Phase 3: Pull Request Factory

理想形。

```text
AIがbranch作成
JSON更新
Validation実行
Audit更新
Pull Request作成
ユーザーがApprove
```

---

## Required Checks

PR作成前に以下を確認する。

```text
1. JSON Schema validation
2. Cross-file reference validation
3. Duplicate modelId check
4. Duplicate alias check
5. Duplicate keyword check
6. Broad keyword check
7. Canonical Name check
8. Coverage update check
9. CHANGELOG update check
```

---

## PR Title Rule

形式:

```text
Data: Add {tier} {brand_or_scope} master updates
```

例:

```text
Data: Add Tier A Salomon master updates
Data: Improve Tier S ASICS aliases
Data: Add Tier B outdoor brand models
```

---

## PR Body Rule

PR本文には以下を必ず含める。

```text
## Summary

## Added

## Changed

## Validation

## Audit Result

## Remaining TODO
```

---

## First Automation Target

最初に自動化する対象:

```text
Tier S data JSON監査
```

次:

```text
Tier A候補作成
```

その次:

```text
Tier A PR作成
```

---

## Not in Scope Yet

MVPでは以下は自動化対象外。

```text
Variant
Colorway
Style Code
Market Price
Release Calendar
User ownership data
```

---

## Final Principle

Kick×Kick AI Data Factory は、データ量を増やすためだけの仕組みではない。

目的は、検索体験を壊さずに、高純度なスニーカーマスターデータを継続的に育てることである。
