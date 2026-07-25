#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_clarks_v0.6.6.json"
VERSION = "0.6.6"
UPDATED_AT = "2026-07-21"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {
    "clarks", "クラークス", "wallabee", "boot", "desert", "trek", "torhill",
    "bee", "hi", "gtx", "gore-tex", "ゴアテックス", "shoes", "lifestyle"
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
    text = text.replace("# Kick×Kick Model Master Coverage v3.2", "# Kick×Kick Model Master Coverage v3.3")
    marker = "| BIRKENSTOCK | PASS 12 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した12モデル系列を追加。色・素材・幅・EVA・フットベッド違いは別モデルとして数えない。 |"
    row = marker + "\n| CLARKS | PASS 8 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した8モデル系列を追加。色・素材・性別・季節仕様は別モデルとして数えない。 |"
    if "| CLARKS | PASS 8 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（BIRKENSTOCK完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（CLARKS完了後）")
    if "2026-07-21 v0.6.6" not in text:
        text = text.rstrip() + "\n\n2026-07-21 v0.6.6\n- CLARKS 8モデル系列を追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v3.4", "# Kick×Kick Task Board v3.5")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.5 SYNCED / BIRKENSTOCK PASS 12", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.6 SYNCED / CLARKS PASS 8")
    if "## 2026-07-21 CLARKS v0.6.6" not in text:
        text = text.rstrip() + "\n\n## 2026-07-21 CLARKS v0.6.6\n- [x] CLARKS 8モデル系列追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.6 CLARKS", """
## v0.6.6 CLARKS
- Eight high-confidence model families were confirmed against the official CLARKS Japan catalog and mirrored to app assets.
- Colors, materials, gender and seasonal editions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as CLARKS, Wallabee, Boot, Desert, Trek, Torhill and GTX are blocked.
""")
    append_once(DATA / "validation_rules.md", "## CLARKS v0.6.6 audit", """
## CLARKS v0.6.6 audit
Standalone brand names, partial model words, category words and technology words are rejected. Complete brand-qualified English/Japanese phrases are allowed. Colors, materials, gender and seasonal editions are not promoted to independent model records.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.6 - 2026-07-21", """
## 0.6.6 - 2026-07-21
- Added eight audited CLARKS model families confirmed in the official Japan catalog.
- Added high-precision aliases and search keywords.
- Avoided duplicate model inflation from colors, materials, gender and seasonal editions.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "clarks" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("CLARKS staging is not merge-ready")
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
    print("CLARKS v0.6.6 sync complete")


if __name__ == "__main__":
    main()
