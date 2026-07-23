#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_crocs_v0.5.9.json"
VERSION = "0.5.9"
UPDATED_AT = "2026-07-12"

TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}

BROAD_TERMS = {
    "clog", "classic", "platform", "crush", "recovery", "literide", "crocs"
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
    for item in staged_items:
        key = unique_key(kind, item)
        if key not in existing:
            master["items"].append(item)
            existing.add(key)
    master["version"] = VERSION
    master["updatedAt"] = UPDATED_AT
    return master


def validate(payloads: dict[str, dict[str, Any]], staging: dict[str, Any]) -> None:
    model_ids = [item["id"] for item in payloads["models"]["items"]]
    if len(model_ids) != len(set(model_ids)):
        raise ValueError("Duplicate model IDs detected")
    model_id_set = set(model_ids)
    for kind in ("aliases", "searchKeywords"):
        missing = [item["modelId"] for item in payloads[kind]["items"] if item["modelId"] not in model_id_set]
        if missing:
            raise ValueError(f"Broken {kind} references: {missing[:5]}")
    staged_ids = {item["id"] for item in staging["models"]}
    if not staged_ids.issubset(model_id_set):
        raise ValueError("Not all staged crocs models were merged")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "crocs" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("Crocs staging payload is not merge-ready")
    assert_safe_terms(staging)
    payloads = {
        key: merge_items(key, paths[0], staging[key])
        for key, paths in TARGETS.items()
    }
    validate(payloads, staging)
    for key, payload in payloads.items():
        data_path, app_path = TARGETS[key]
        write_compact_json(data_path, payload)
        write_compact_json(app_path, payload)
    print("crocs v0.5.9 sync complete")


if __name__ == "__main__":
    main()
