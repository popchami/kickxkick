#!/usr/bin/env python3
"""Validate Kick×Kick data master JSON files.

This script intentionally uses only Python standard library so it can run in
GitHub Actions without extra dependencies.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

REQUIRED_FILES = {
    "brands": DATA / "brands.json",
    "models": DATA / "models.json",
    "aliases": DATA / "aliases.json",
    "keywords": DATA / "search_keywords.json",
}

BROAD_TERMS = {
    "air",
    "max",
    "gel",
    "cloud",
    "nike",
    "adidas",
    "jordan",
    "new balance",
    "asics",
}

ID_PATTERN = re.compile(r"^[a-z0-9_]+$")
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise ValueError(f"Missing file: {path}")
    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in {path}: {e}") from e
    if not isinstance(data, dict):
        raise ValueError(f"Root must be object: {path}")
    return data


def require_header(name: str, data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if not isinstance(data.get("version"), str) or not data["version"]:
        errors.append(f"{name}: version is required")
    if not isinstance(data.get("updatedAt"), str) or not DATE_PATTERN.match(data["updatedAt"]):
        errors.append(f"{name}: updatedAt must be YYYY-MM-DD")
    if not isinstance(data.get("items"), list):
        errors.append(f"{name}: items must be an array")
    return errors


def validate() -> list[str]:
    errors: list[str] = []
    loaded = {name: load_json(path) for name, path in REQUIRED_FILES.items()}

    for name, data in loaded.items():
        errors.extend(require_header(name, data))

    brand_ids: set[str] = set()
    model_ids: set[str] = set()

    for item in loaded["brands"].get("items", []):
        if not isinstance(item, dict):
            errors.append("brands: item must be object")
            continue
        brand_id = item.get("brandId")
        if not isinstance(brand_id, str) or not ID_PATTERN.match(brand_id):
            errors.append(f"brands: invalid brandId: {brand_id}")
            continue
        if brand_id in brand_ids:
            errors.append(f"brands: duplicate brandId: {brand_id}")
        brand_ids.add(brand_id)
        if not isinstance(item.get("brandName"), str) or not item["brandName"]:
            errors.append(f"brands: brandName required for {brand_id}")
        if item.get("tier") not in {"S", "A", "B", "C", "D", "E", "Planned"}:
            errors.append(f"brands: invalid tier for {brand_id}: {item.get('tier')}")
        if not isinstance(item.get("isEnabled"), bool):
            errors.append(f"brands: isEnabled must be boolean for {brand_id}")

    model_key_pairs: set[tuple[str, str]] = set()
    for item in loaded["models"].get("items", []):
        if not isinstance(item, dict):
            errors.append("models: item must be object")
            continue
        model_id = item.get("id")
        brand_id = item.get("brandId")
        model_name = item.get("modelName")
        if not isinstance(model_id, str) or not ID_PATTERN.match(model_id):
            errors.append(f"models: invalid id: {model_id}")
            continue
        if model_id in model_ids:
            errors.append(f"models: duplicate id: {model_id}")
        model_ids.add(model_id)
        if brand_id not in brand_ids:
            errors.append(f"models: brandId not found for {model_id}: {brand_id}")
        if not isinstance(model_name, str) or not model_name:
            errors.append(f"models: modelName required for {model_id}")
        else:
            pair = (str(brand_id), model_name.lower())
            if pair in model_key_pairs:
                errors.append(f"models: duplicate brand/modelName: {brand_id} / {model_name}")
            model_key_pairs.add(pair)
        if item.get("source") not in {"master", "user_input"}:
            errors.append(f"models: invalid source for {model_id}: {item.get('source')}")

    alias_pairs: set[tuple[str, str]] = set()
    for item in loaded["aliases"].get("items", []):
        if not isinstance(item, dict):
            errors.append("aliases: item must be object")
            continue
        model_id = item.get("modelId")
        alias = item.get("alias")
        if model_id not in model_ids:
            errors.append(f"aliases: modelId not found: {model_id}")
        if not isinstance(alias, str) or not alias:
            errors.append(f"aliases: alias required for {model_id}")
            continue
        normalized = alias.strip().lower()
        pair = (str(model_id), normalized)
        if pair in alias_pairs:
            errors.append(f"aliases: duplicate alias for {model_id}: {alias}")
        alias_pairs.add(pair)
        if normalized in BROAD_TERMS:
            errors.append(f"aliases: broad alias is forbidden: {alias}")

    keyword_pairs: set[tuple[str, str]] = set()
    for item in loaded["keywords"].get("items", []):
        if not isinstance(item, dict):
            errors.append("search_keywords: item must be object")
            continue
        model_id = item.get("modelId")
        keyword = item.get("keyword")
        if model_id not in model_ids:
            errors.append(f"search_keywords: modelId not found: {model_id}")
        if not isinstance(keyword, str) or not keyword:
            errors.append(f"search_keywords: keyword required for {model_id}")
            continue
        normalized = keyword.strip().lower()
        pair = (str(model_id), normalized)
        if pair in keyword_pairs:
            errors.append(f"search_keywords: duplicate keyword for {model_id}: {keyword}")
        keyword_pairs.add(pair)
        if normalized in BROAD_TERMS:
            errors.append(f"search_keywords: broad keyword is forbidden: {keyword}")
        if len(normalized) == 1 and normalized.isalnum():
            errors.append(f"search_keywords: 1-character keyword is forbidden: {keyword}")

    return errors


def main() -> int:
    try:
        errors = validate()
    except ValueError as e:
        print(f"ERROR: {e}")
        return 1

    if errors:
        print("Kick×Kick data validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Kick×Kick data validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
