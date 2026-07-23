#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "specs" / "KICKXKICK_TASK_BOARD.md"

text = PATH.read_text(encoding="utf-8")
old = """ブランド・モデル・検索基盤はMVPリリース可能ライン。
Tier S / Tier A はPASS。
Tier BはHOKA / Saucony / SALOMON / MERRELL / BROOKSを追加し、Alias / searchKeywords までPASS化済み。
Tier Cはブランド名先行登録済み。SKECHERSはv0.5.3で8モデルまで拡張。crocsはv0.5.4で4モデル追加開始。
Dr.Martensはv0.5.7-merge-ready-auditedとして15モデルを検証済みステージング化。同期スクリプトあり。本体JSON反映待ち。
ABC-MARTなど国内流通リファレンスを基準に、今後もデータ資産を継続育成する。
data/models.json・aliases.json・search_keywords.json と app/assets/data 側は v0.5.4 として同期済み。
次はリポジトリ実行環境で Dr.Martens 同期スクリプトを実行し、data/*.json と app/assets/data/*.json のSHA一致を確認する。"""
new = """ブランド・モデル・検索基盤はMVPリリース可能ライン。
Tier S / Tier A / Tier B はモデル・Alias・searchKeywordsまでPASS。
Tier Cはブランド名を先行登録済みで、SKECHERS 16、crocs 10、Dr.Martens 15、Timberland 6、FILA 6、Danner 6、RED WING 6、HAWKINS 8、BIRKENSTOCK 12モデル系列までPASS。
ABC-MARTなど国内流通リファレンスと各ブランド公式情報を基準に、色・素材・サイズ違いを水増しせずデータ資産を継続育成する。
data/models.json・aliases.json・search_keywords.json と app/assets/data 側は v0.6.5 として同期済み。
次はSearch MVP実動作テスト、Tier S〜Bの国内流通差分監査、次のTier Cブランド集中拡張を進める。"""
if old not in text:
    raise SystemExit("stale Current Status block not found")
text = text.replace(old, new)
text = text.replace("- [ ] `python3 data/sync_dr_martens_v0.5.7.py` 実行", "- [x] `python3 data/sync_dr_martens_v0.5.7.py` 実行")
text = text.replace("- [ ] Dr.Martens app/assets/data/*.json 同期", "- [x] Dr.Martens app/assets/data/*.json 同期")
text = text.replace("- [ ] 実行後の data/*.json / app/assets/data/*.json SHA一致確認", "- [x] 実行後の data/*.json / app/assets/data/*.json SHA一致確認")
PATH.write_text(text, encoding="utf-8")
print("Task Board v0.6.5 consistency fix complete")
