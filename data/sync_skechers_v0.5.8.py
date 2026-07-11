#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_skechers_v0.5.8.json"
VERSION = "0.5.8"
UPDATED_AT = "2026-07-11"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {"walk","run","sport","street","golf","shoe","sneaker","slip-on","comfort","cushion","arch","flex","summits","equalizer","reggae"}

def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))

def key(kind: str, item: dict[str, Any]) -> tuple[str, str]:
    if kind == "models": return (item["id"], item["brandId"])
    if kind == "aliases": return (item["modelId"], item["alias"].casefold())
    return (item["modelId"], item["keyword"].casefold())

def main() -> None:
    staging = load(STAGING)
    if staging.get("brandId") != "skechers" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("SKECHERS staging is not merge-ready")
    for kind, field in (("aliases", "alias"), ("searchKeywords", "keyword")):
        for item in staging[kind]:
            if item[field].strip().casefold() in BROAD_TERMS:
                raise ValueError(f"Blocked broad term: {item[field]}")
    model_ids = {m["id"] for m in staging["models"]}
    for kind in ("aliases", "searchKeywords"):
        missing = {i["modelId"] for i in staging[kind]} - model_ids
        if missing:
            raise ValueError(f"Unknown staged model references: {sorted(missing)}")
    for kind, (data_path, app_path) in TARGETS.items():
        master = load(data_path)
        existing = {key(kind, item) for item in master["items"]}
        for item in staging[kind]:
            if key(kind, item) not in existing:
                master["items"].append(item)
                existing.add(key(kind, item))
        master["version"] = VERSION
        master["updatedAt"] = UPDATED_AT
        text = json.dumps(master, ensure_ascii=False, separators=(",", ":"))
        data_path.write_text(text, encoding="utf-8")
        app_path.write_text(text, encoding="utf-8")
    print("SKECHERS v0.5.8 sync complete")

if __name__ == "__main__":
    main()
