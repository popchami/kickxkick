#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_fila_v0.6.1.json"
VERSION = "0.6.1"
UPDATED_AT = "2026-07-14"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {"fila", "disruptor", "ray", "tracer", "grant", "hill", "original", "fitness", "basketball", "lifestyle"}


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


def append_once(path: Path, marker: str, block: str) -> None:
    text = path.read_text(encoding="utf-8")
    if marker not in text:
        path.write_text(text.rstrip() + "\n\n" + block.strip() + "\n", encoding="utf-8")


def update_docs() -> None:
    coverage = ROOT / "specs" / "MODEL_MASTER_COVERAGE.md"
    text = coverage.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Model Master Coverage v2.7", "# Kick×Kick Model Master Coverage v2.8")
    marker = "| Timberland | PASS 6 | PASS | PASS | PASS | PASS | 公式・主要流通で識別可能な6モデルを追加。一般語単体は除外。 |"
    row = marker + "\n| FILA | PASS 6 | PASS | PASS | PASS | PASS | 高確度6モデルを追加。ブランド・一般語単体は除外。 |"
    if "| FILA | PASS 6 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（Timberland完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（FILA完了後）")
    if "2026-07-14 v0.6.1" not in text:
        text = text.rstrip() + "\n\n2026-07-14 v0.6.1\n- FILA 6モデルを追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v2.9", "# Kick×Kick Task Board v3.0")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.0 SYNCED / TIMBERLAND PASS 6", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.1 SYNCED / FILA PASS 6")
    if "## 2026-07-14 FILA v0.6.1" not in text:
        text = text.rstrip() + "\n\n## 2026-07-14 FILA v0.6.1\n- [x] FILA 6モデル追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.1 FILA", """
## v0.6.1 FILA
- 6 high-confidence models added and mirrored to app assets.
- Only brand-qualified aliases and full-name Japanese search keywords were added.
- Broad standalone terms such as FILA, Original, Fitness, Grant and Hill are blocked.
""")
    append_once(DATA / "validation_rules.md", "## FILA v0.6.1 audit", """
## FILA v0.6.1 audit
Standalone brand, person-name fragments, category and generic product terms are rejected. Full canonical names and brand-qualified Japanese phrases are allowed.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.1 - 2026-07-14", """
## 0.6.1 - 2026-07-14
- Added 6 audited FILA models.
- Added high-precision aliases and search keywords.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "fila" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("FILA staging is not merge-ready")
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
    print("FILA v0.6.1 sync complete")


if __name__ == "__main__":
    main()
