#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_birkenstock_v0.6.5.json"
VERSION = "0.6.5"
UPDATED_AT = "2026-07-20"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {
    "birkenstock", "ビルケンシュトック", "arizona", "boston", "gizeh", "madrid",
    "zurich", "zürich", "kyoto", "milano", "mayari", "florida", "ramses",
    "atacama", "mogami", "sandal", "sandals", "clog", "clogs", "eva",
    "leather", "suede", "soft footbed"
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
    text = text.replace("# Kick×Kick Model Master Coverage v3.1", "# Kick×Kick Model Master Coverage v3.2")
    marker = "| HAWKINS | PASS 8 | PASS | PASS | PASS | PASS | ABC-MART公式商品ページで確認した8系列を追加。色・サイズ・品番改訂は別モデルとして数えない。 |"
    row = marker + "\n| BIRKENSTOCK | PASS 12 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した12モデル系列を追加。色・素材・幅・EVA・フットベッド違いは別モデルとして数えない。 |"
    if "| BIRKENSTOCK | PASS 12 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（HAWKINS完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（BIRKENSTOCK完了後）")
    if "2026-07-20 v0.6.5" not in text:
        text = text.rstrip() + "\n\n2026-07-20 v0.6.5\n- BIRKENSTOCK 12モデル系列を追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v3.3", "# Kick×Kick Task Board v3.4")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.4 SYNCED / HAWKINS PASS 8", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.5 SYNCED / BIRKENSTOCK PASS 12")
    if "## 2026-07-20 BIRKENSTOCK v0.6.5" not in text:
        text = text.rstrip() + "\n\n## 2026-07-20 BIRKENSTOCK v0.6.5\n- [x] BIRKENSTOCK 12モデル系列追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.5 BIRKENSTOCK", """
## v0.6.5 BIRKENSTOCK
- 12 high-confidence model families were confirmed against the official BIRKENSTOCK Japan catalog and mirrored to app assets.
- Colors, materials, widths, EVA editions and soft-footbed editions were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as BIRKENSTOCK, model-family names, Sandal, Clog, EVA, Leather and Suede are blocked.
""")
    append_once(DATA / "validation_rules.md", "## BIRKENSTOCK v0.6.5 audit", """
## BIRKENSTOCK v0.6.5 audit
Standalone brand names, model-family names, category words and material words are rejected. Complete brand-qualified English/Japanese phrases are allowed. Colors, materials, widths, EVA variants and footbed variants are not promoted to independent model records.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.5 - 2026-07-20", """
## 0.6.5 - 2026-07-20
- Added 12 audited BIRKENSTOCK model families confirmed in the official Japan catalog.
- Added high-precision aliases and search keywords.
- Avoided duplicate model inflation from colors, materials, widths, EVA variants and footbed variants.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "birkenstock" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("BIRKENSTOCK staging is not merge-ready")
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
    print("BIRKENSTOCK v0.6.5 sync complete")


if __name__ == "__main__":
    main()
