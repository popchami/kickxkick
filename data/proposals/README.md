# Kick×Kick Data Proposals

## Purpose

このディレクトリは、AI Data Factory が作成するデータ更新候補を一時的に置く場所である。

本番データである `data/*.json` に直接反映する前に、提案内容をレビューし、品質チェックを行う。

---

## Principle

```text
Propose first.
Validate next.
Human approves.
Then merge.
```

AIはmainの本データを直接増やし続けない。

---

## Proposal File Naming

形式:

```text
YYYY-MM-DD_{tier}_{scope}.json
```

例:

```text
2026-06-25_tier_a_salomon.json
2026-06-25_tier_s_asics_alias_fix.json
2026-06-25_tier_b_outdoor_models.json
```

---

## Proposal Structure

```json
{
  "version": "0.1.0",
  "createdAt": "2026-06-25",
  "scope": "tier_a_salomon",
  "status": "proposal",
  "brands": [],
  "models": [],
  "aliases": [],
  "searchKeywords": [],
  "audit": {
    "risk": "low",
    "notes": []
  }
}
```

---

## Review Rule

提案ファイルは以下を満たすこと。

```text
1. 低確度データを含まない
2. 広すぎるAliasを含まない
3. 広すぎるsearchKeywordsを含まない
4. Canonical Nameが明確
5. 反映先のdata/*.jsonと矛盾しない
```

---

## Promotion Flow

```text
proposal JSON
↓
review
↓
validate
↓
merge into data/*.json
↓
update data/CHANGELOG.md
↓
update coverage/audit files
```

---

## Current Status

このディレクトリは、AI Data Factory のPhase 2以降で本格利用する。
