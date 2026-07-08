#!/usr/bin/env python3
"""
Kick×Kick data sync helper for Dr.Martens v0.5.7.

Purpose:
- Merge data/staging_dr_martens_v0.5.5.json into compressed root JSON masters.
- Sync the same output to app/assets/data/*.json.
- Preserve high-purity Alias/searchKeywords rules.

Usage from repository root:
    python3 data/sync_dr_martens_v0.5.7.py

This script is intentionally narrow and deterministic.
It does not scrape external sites and does not add low-confidence models.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_dr_martens_v0.5.5.json"
VERSION = "0.5.7"
UPDATED_AT = "2026-07-08"

TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}

BROAD_TERMS = {
    "docs",
    "dms",
    "boot",
    "shoe",
    "loafers",
    "loafer",
    "sandals",
    "sandal",
    "mules",
    "mule",
    "chelsea",
    "platform",
    "martens",
    "dr.martens",
    "doc martens",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_compact_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def unique_key(kind: str, item: dict[str, Any]) -> tuple[str, str]:
    if kind == "models":
        return (item["id"], item["brandId"])
    if kind == "aliases":
        return (item["modelId"], item["alias"].casefold())
    if kind == "searchKeywords":
        return (item["modelId"], item["keyword"].casefold())
    raise ValueError(f"Unsupported kind: {kind}")


def assert_safe_terms(staging: dict[str, Any]) -> None:
    for kind, value_key in (("aliases", "alias"), ("searchKeywords", "keyword")):
        for item in staging[kind]:
            value = item[value_key].strip().casefold()
            if value in BROAD_TERMS:
                raise ValueError(f"Blocked broad {kind} term: {item[value_key]}")


def merge_items(kind: str, master_path: Path, staged_items: list[dict[str, Any]]) -> dict[str, Any]:
    master = load_json(master_path)
    existing = {unique_key(kind, item) for item in master["items"]}

    added = 0
    for item in staged_items:
        key = unique_key(kind, item)
        if key not in existing:
            master["items"].append(item)
            existing.add(key)
            added += 1

    master["version"] = VERSION
    master["updatedAt"] = UPDATED_AT
    print(f"{kind}: added {added}, total {len(master['items'])}")
    return master


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "dr_martens":
        raise ValueError("Unexpected staging brandId")
    if not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("Staging payload is not merge-ready")

    assert_safe_terms(staging)

    merged_payloads: dict[str, dict[str, Any]] = {}
    for staging_key, (data_path, _) in TARGETS.items():
        merged_payloads[staging_key] = merge_items(staging_key, data_path, staging[staging_key])

    for staging_key, payload in merged_payloads.items():
        data_path, app_path = TARGETS[staging_key]
        write_compact_json(data_path, payload)
        write_compact_json(app_path, payload)

    print("Dr.Martens v0.5.7 sync complete.")


if __name__ == "__main__":
    main()
