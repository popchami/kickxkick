#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_timberland_v0.6.0.json"
VERSION = "0.6.0"
UPDATED_AT = "2026-07-13"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {"boot","boots","waterproof","hiker","field","motion","access","low","mid","timberland"}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def unique_key(kind: str, item: dict[str, Any]) -> tuple[str, str]:
    if kind == "models":
        return item["id"], item["brandId"]
    key = "alias" if kind == "aliases" else "keyword"
    return item["modelId"], item[key].casefold()


def merge(kind: str, path: Path, staged: list[dict[str, Any]]) -> dict[str, Any]:
    master = load_json(path)
    existing = {unique_key(kind, item) for item in master["items"]}
    for item in staged:
        if unique_key(kind, item) not in existing:
            master["items"].append(item)
            existing.add(unique_key(kind, item))
    master["version"] = VERSION
    master["updatedAt"] = UPDATED_AT
    return master


def update_docs() -> None:
    coverage = ROOT / "specs" / "MODEL_MASTER_COVERAGE.md"
    text = coverage.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Model Master Coverage v2.6", "# Kick×Kick Model Master Coverage v2.7")
    marker = "| Dr.Martens | PASS 15 | PASS | PASS | PASS | PASS | 15モデルを本体JSONとapp/assets/dataへ同期済み。広すぎるAlias/searchKeywordsは除外済み。 |"
    row = marker + "\n| Timberland | PASS 6 | PASS | PASS | PASS | PASS | 公式・主要流通で識別可能な6モデルを追加。一般語単体は除外。 |"
    if "| Timberland | PASS 6 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加", "2. 次のTier Cブランドを1ブランド集中で追加（Timberland完了後）")
    text += "\n\n2026-07-13 v0.6.0\n- Timberland 6モデルを追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v2.8", "# Kick×Kick Task Board v2.9")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.5.4 SYNCED / DR.MARTENS v0.5.7 MERGE-READY-AUDITED", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.0 SYNCED / TIMBERLAND PASS 6")
    text += "\n\n## 2026-07-13 Timberland v0.6.0\n- [x] Timberland 6モデル追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    readme = DATA / "README.md"
    text = readme.read_text(encoding="utf-8")
    text += "\n\n## v0.6.0 Timberland\n- 6 high-confidence models added and mirrored to app assets.\n- Model-specific aliases and Japanese full-name search keywords only.\n- Broad standalone terms such as Boot, Waterproof, Motion and Timberland are blocked.\n"
    readme.write_text(text, encoding="utf-8")

    rules = DATA / "validation_rules.md"
    text = rules.read_text(encoding="utf-8")
    text += "\n\n## Timberland v0.6.0 audit\nStandalone category, feature, position and brand terms are rejected. Full canonical names and brand-qualified Japanese phrases are allowed.\n"
    rules.write_text(text, encoding="utf-8")

    changelog = DATA / "CHANGELOG.md"
    text = changelog.read_text(encoding="utf-8")
    text += "\n\n## 0.6.0 - 2026-07-13\n- Added 6 audited Timberland models.\n- Added high-precision aliases and search keywords.\n- Synced root data and Flutter app assets.\n- Updated README, validation rules, coverage and task board.\n"
    changelog.write_text(text, encoding="utf-8")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "timberland" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("Timberland staging is not merge-ready")
    for kind, key in (("aliases", "alias"), ("searchKeywords", "keyword")):
        for item in staging[kind]:
            if item[key].strip().casefold() in BROAD_TERMS:
                raise ValueError(f"Blocked broad term: {item[key]}")
    payloads = {kind: merge(kind, paths[0], staging[kind]) for kind, paths in TARGETS.items()}
    model_ids = [item["id"] for item in payloads["models"]["items"]]
    if len(model_ids) != len(set(model_ids)):
        raise ValueError("Duplicate model IDs")
    model_set = set(model_ids)
    for kind in ("aliases", "searchKeywords"):
        missing = [item["modelId"] for item in payloads[kind]["items"] if item["modelId"] not in model_set]
        if missing:
            raise ValueError(f"Broken {kind} references: {missing[:5]}")
    for kind, payload in payloads.items():
        data_path, app_path = TARGETS[kind]
        write_json(data_path, payload)
        write_json(app_path, payload)
    update_docs()
    print("Timberland v0.6.0 sync complete")


if __name__ == "__main__":
    main()
