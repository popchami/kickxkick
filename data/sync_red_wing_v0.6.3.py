#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
APP_DATA = ROOT / "app" / "assets" / "data"
STAGING = DATA / "staging_red_wing_v0.6.3.json"
VERSION = "0.6.3"
UPDATED_AT = "2026-07-17"
TARGETS = {
    "models": (DATA / "models.json", APP_DATA / "models.json"),
    "aliases": (DATA / "aliases.json", APP_DATA / "aliases.json"),
    "searchKeywords": (DATA / "search_keywords.json", APP_DATA / "search_keywords.json"),
}
BROAD_TERMS = {
    "red wing", "classic", "moc", "iron", "ranger", "blacksmith", "beckman",
    "postman", "oxford", "chelsea", "boot", "boots", "shoe", "shoes"
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
    text = text.replace("# Kick×Kick Model Master Coverage v2.9", "# Kick×Kick Model Master Coverage v3.0")
    marker = "| Danner | PASS 6 | PASS | PASS | PASS | PASS | 高確度6モデルを追加。ブランド・一般語単体は除外。 |"
    row = marker + "\n| RED WING | PASS 6 | PASS | PASS | PASS | PASS | 公式日本カタログで確認した6モデル系列を追加。品番・素材違いは別モデルとして数えない。 |"
    if "| RED WING | PASS 6 |" not in text:
        text = text.replace(marker, row)
    text = text.replace("2. 次のTier Cブランドを1ブランド集中で追加（Danner完了後）", "2. 次のTier Cブランドを1ブランド集中で追加（RED WING完了後）")
    if "2026-07-17 v0.6.3" not in text:
        text = text.rstrip() + "\n\n2026-07-17 v0.6.3\n- RED WING 6モデル系列を追加\n- Alias / searchKeywordsを高純度監査\n- data/*.json と app/assets/data/*.json を同期\n"
    coverage.write_text(text, encoding="utf-8")

    task = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"
    text = task.read_text(encoding="utf-8")
    text = text.replace("# Kick×Kick Task Board v3.1", "# Kick×Kick Task Board v3.2")
    text = text.replace("ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.2 SYNCED / DANNER PASS 6", "ACTIVE / MVP DATA PASS / MARKET REFERENCE GROWTH / DATA v0.6.3 SYNCED / RED WING PASS 6")
    if "## 2026-07-17 RED WING v0.6.3" not in text:
        text = text.rstrip() + "\n\n## 2026-07-17 RED WING v0.6.3\n- [x] RED WING 6モデル系列追加\n- [x] Alias / searchKeywords高純度監査\n- [x] data / app assets同期\n- [x] README / validation / CHANGELOG / Coverage整合\n- [ ] Search MVP実動作テスト\n"
    task.write_text(text, encoding="utf-8")

    append_once(DATA / "README.md", "## v0.6.3 RED WING", """
## v0.6.3 RED WING
- 6 high-confidence model families were added and mirrored to app assets.
- Official Japanese catalog naming was used; color, leather and style-number variants were not counted as separate models.
- Only brand-qualified aliases and complete English/Japanese search phrases were added.
- Broad standalone terms such as RED WING, Classic, Moc, Iron, Ranger, Postman, Oxford, Chelsea and Boot are blocked.
""")
    append_once(DATA / "validation_rules.md", "## RED WING v0.6.3 audit", """
## RED WING v0.6.3 audit
Standalone brand names, category words and partial family-name fragments are rejected. Complete canonical family names and brand-qualified English/Japanese phrases are allowed. Product style numbers, colors and leather variants are not promoted to independent model records.
""")
    append_once(DATA / "CHANGELOG.md", "## 0.6.3 - 2026-07-17", """
## 0.6.3 - 2026-07-17
- Added 6 audited RED WING model families.
- Added high-precision aliases and search keywords.
- Avoided duplicate model inflation from color, leather and style-number variants.
- Synced root data and Flutter app assets.
- Updated README, validation rules, coverage and task board.
""")


def main() -> None:
    staging = load_json(STAGING)
    if staging.get("brandId") != "red_wing" or not staging.get("audit", {}).get("readyForRootJsonMerge"):
        raise ValueError("RED WING staging is not merge-ready")
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
    print("RED WING v0.6.3 sync complete")


if __name__ == "__main__":
    main()
