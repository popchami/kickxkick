#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_sperry_topsider_v0.6.9.json"
VERSION = "0.6.9"
UPDATED_AT = "2026-07-25"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {
    "sperry", "sperry topsider", "sperry top-sider", "スペリー", "トップサイダー",
    "authentic", "original", "gold cup", "billfish", "striper", "cvo",
    "boat shoe", "sneaker", "1-eye", "2-eye", "3-eye"
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
        key = unique_key(kind, item)
        if key not in existing:
            master["items"].append(item)
            existing.add(key)
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
    text = text.replace("# Kick×Kick Model Master Coverage v3.5", "# Kick×Kick Model Master Coverage v3.6")
    marker = "| UNDER ARMOUR | PASS 8 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した8モデル系列を追加。色・性別・サイズ・限定カラーは別モデルとして数えない。 |"
    row = marker + "\n| SPERRY TOPSIDER | PASS 5 | PASS | PASS | PASS | PASS | Sperry公式商品・コレクションページで確認した5モデル系列を追加。色・素材・性別・幅・品番違いは別モデルとして数えない。 |"
    if "| SPERRY TOPSIDER | PASS 5 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（UNDER ARMOUR完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（SPERRY TOPSIDER完了後）")
    if "2026-07-25 v0.6.9" not in text:
        text = text.rstrip() + "\n\n2026-07-25 v0.6.9\n- SPERRY TOPSIDER 5モデル系列を追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v3.7", "# Kick×Kick Task Board v3.8")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.8 SYNCED / UNDER ARMOUR PASS 8", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.9 SYNCED / SPERRY TOPSIDER PASS 5")
    if "## 2026-07-25 SPERRY TOPSIDER v0.6.9" not in text:
        text = text.rstrip() + "\n\n## 2026-07-25 SPERRY TOPSIDER v0.6.9\n- [x] SPERRY TOPSIDER 5モデル系列追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.9 SPERRY TOPSIDER", """
## v0.6.9 SPERRY TOPSIDER
- Five high-confidence footwear model families were confirmed against official Sperry product and collection pages and mirrored to app assets.
- Colors, materials, gender, width and style-code revisions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as SPERRY, Authentic, Original, Gold Cup, Billfish, Boat Shoe and Sneaker are blocked.
""")
    append_once(DATA / "validation_rules.md", "## SPERRY TOPSIDER v0.6.9 audit", """
## SPERRY TOPSIDER v0.6.9 audit
Standalone brand names, partial model words, eye-count fragments, category words and generic footwear terms are rejected. Complete brand-qualified English/Japanese phrases are allowed. Colors, materials, gender, width and style-code revisions are not promoted to independent model records.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.9 - 2026-07-25", """
## 0.6.9 - 2026-07-25
- Added five audited SPERRY TOPSIDER footwear model families confirmed on official Sperry pages.
- Added high-precision aliases and search keywords.
- Avoided duplicate model inflation from colors, materials, gender, width and style-code revisions.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "sperry_topsider" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("SPERRY TOPSIDER staging is not merge-ready")
    for kind, key_name in (("aliases", "alias"), ("searchKeywords", "keyword")):
        for item in staging[kind]:
            if item[key_name].strip().casefold() in BROAD_TERMS:
                raise ValueError(f"Blocked broad term: {item[key_name]}")
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
    print("SPERRY TOPSIDER v0.6.9 sync complete")


if __name__ == "__main__":
    main()
