#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_hawkins_v0.6.4.json"
VERSION = "0.6.4"
UPDATED_AT = "2026-07-18"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {
    "hawkins", "ホーキンス", "moc", "mula", "emily", "adela", "mana", "mach",
    "keely", "loafer", "wide", "boot", "boots", "shoe", "shoes", "sneaker",
    "sneakers", "sandal", "sandals", "waterproof"
}


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
    text = text.replace("# Kick×Kick Model Master Coverage v3.0", "# Kick×Kick Model Master Coverage v3.1")
    marker = "| RED WING | PASS 6 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した6モデル系列を追加。品番・素材違いは別モデルとして数えない。 |"
    row = marker + "\n| HAWKINS | PASS 8 | PASS | PASS | PASS | PASS | ABC-MART公式商品ページで確認した8系列を追加。色・サイズ・品番改訂は別モデルとして数えない。 |"
    if "| HAWKINS | PASS 8 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（RED WING完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（HAWKINS完了後）")
    if "2026-07-18 v0.6.4" not in text:
        text = text.rstrip() + "\n\n2026-07-18 v0.6.4\n- HAWKINS 8モデル系列を追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v3.2", "# Kick×Kick Task Board v3.3")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.3 SYNCED / RED WING PASS 6", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.4 SYNCED / HAWKINS PASS 8")
    if "## 2026-07-18 HAWKINS v0.6.4" not in text:
        text = text.rstrip() + "\n\n## 2026-07-18 HAWKINS v0.6.4\n- [x] HAWKINS 8モデル系列追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.4 HAWKINS", """
## v0.6.4 HAWKINS
- 8 high-confidence product families were confirmed against ABC-MART official product pages and mirrored to app assets.
- Colors, sizes and manufacturer-number revisions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as HAWKINS, Boot, Shoe, Sneaker, Sandal, Waterproof and partial model-name fragments are blocked.
""")
    append_once(DATA / "validation_rules.md", "## HAWKINS v0.6.4 audit", """
## HAWKINS v0.6.4 audit
Standalone brand names, category words and partial product-name fragments are rejected. Complete product-family names and brand-qualified English/Japanese phrases are allowed. Colors, sizes and manufacturer-number revisions are not promoted to independent model records.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.4 - 2026-07-18", """
## 0.6.4 - 2026-07-18
- Added 8 audited HAWKINS product families confirmed on ABC-MART official pages.
- Added high-precision aliases and search keywords.
- Avoided duplicate model inflation from colors, sizes and manufacturer-number revisions.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "hawkins" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("HAWKINS staging is not merge-ready")
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
    print("HAWKINS v0.6.4 sync complete")


if __name__ == "__main__":
    main()
