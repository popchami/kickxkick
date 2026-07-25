#!/usr/bin/env python3
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'specs' / 'MODEL_MASTER_COVERAGE.md'
text = path.read_text(encoding='utf-8')
old = '| Tier C | crocs | PASS | 10 | v0.5.9 audited expansion |'
new = '| crocs | PASS 10 | PASS | PASS | PASS | PASS | 10件へ拡張。モデル固有の複合語のみ採用し、広すぎる単独語は除外。 |'
if old not in text and new not in text:
    raise SystemExit('crocs coverage row not found')
path.write_text(text.replace(old, new), encoding='utf-8')
print('crocs coverage row fixed')
