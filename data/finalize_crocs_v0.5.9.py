#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def prepend_after_title(path: Path, marker: str, block: str) -> None:
    text = path.read_text(encoding='utf-8')
    if marker in text:
        return
    lines = text.splitlines(keepends=True)
    insert_at = 1
    while insert_at < len(lines) and lines[insert_at].strip() == '':
        insert_at += 1
    text = ''.join(lines[:insert_at]) + '\n' + block.rstrip() + '\n\n---\n\n' + ''.join(lines[insert_at:])
    path.write_text(text, encoding='utf-8')


def append_once(path: Path, marker: str, block: str) -> None:
    text = path.read_text(encoding='utf-8')
    if marker not in text:
        path.write_text(text.rstrip() + '\n\n' + block.rstrip() + '\n', encoding='utf-8')


changelog = ROOT / 'data' / 'CHANGELOG.md'
prepend_after_title(changelog, '## 2026-07-12 v0.5.9 crocs expansion', '''## 2026-07-12 v0.5.9 crocs expansion

### Added / Updated

- crocsを4モデルから10モデルへ拡張
- 追加: `Classic Platform Clog` / `Classic Crush Clog` / `Mega Crush Clog` / `Mellow Recovery Clog` / `Dylan Clog` / `LiteRide 360 Clog`
- モデル固有のAliasと、ブランド名を含む日本語searchKeywordsを追加
- `data/*.json` と `app/assets/data/*.json` をv0.5.9へ同期

### Audited

- モデルID重複、Alias/searchKeywords参照先、JSON構文、data/app assets一致を検証
- `Clog` / `Classic` / `Platform` / `Crush` / `Recovery` / `LiteRide` / `Crocs`単体は広すぎるため除外

### Remaining

- Search MVP実動作テスト
- Tier S〜Bの国内流通差分監査
- 次のTier Cブランド集中拡張''')

append_once(ROOT/'data'/'README.md', '## v0.5.9 crocs同期', '''## v0.5.9 crocs同期

- crocs: 10モデル（既存4 + 追加6）
- root JSONと`app/assets/data`は同一内容で同期する
- Alias/searchKeywordsはモデル固有の複合語のみ採用し、広すぎる単独語は除外する
- 同期: `python3 data/sync_crocs_v0.5.9.py`''')

append_once(ROOT/'data'/'validation_rules.md', '## v0.5.9追加監査', '''## v0.5.9追加監査

- staging内のAlias/searchKeywordsが禁止広義語と完全一致した場合は同期を失敗させる
- 全Alias/searchKeywordsのmodelIdがmodels.jsonに存在すること
- model IDは全体で一意であること
- `data/*.json`と`app/assets/data/*.json`はバイト一致すること''')

coverage = ROOT/'specs'/'MODEL_MASTER_COVERAGE.md'
text = coverage.read_text(encoding='utf-8')
if 'crocs | PASS | 10' not in text:
    text = re.sub(r'(?im)^.*crocs.*$', '| Tier C | crocs | PASS | 10 | v0.5.9 audited expansion |', text, count=1)
    if 'crocs | PASS | 10' not in text:
        text += '\n| Tier C | crocs | PASS | 10 | v0.5.9 audited expansion |\n'
    coverage.write_text(text, encoding='utf-8')

append_once(ROOT/'specs'/'KICKXKICK_TASK_BOARD.md', '## 2026-07-12 crocs v0.5.9', '''## 2026-07-12 crocs v0.5.9

- [x] crocsを10モデルへ拡張
- [x] Alias / searchKeywords高純度監査
- [x] data / app assets同期
- [x] README / validation / CHANGELOG / Coverage整合
- [ ] Search MVP実動作テスト
- [ ] 次ブランド集中拡張''')

print('crocs v0.5.9 docs finalized')
