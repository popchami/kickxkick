# Kick×Kick Audit Tracker

## Purpose

Kick×Kick の監査・保留・再チェック対象を管理するファイル。

「あとで直す」を忘れないため、未完了の作業は必ずここに残す。

---

## Status Rule

- OPEN: 未対応
- IN_PROGRESS: 対応中
- DONE: 対応完了
- BLOCKED: ツールや安全チェックなどで一時的に更新できなかったもの

---

## OPEN

### Model Master Audit Notes

以下はモデル候補リスト本体は修正済みだが、監査メモ欄の文言を再確認する対象。

- specs/MODEL_MASTER/NEW_BALANCE.md
- specs/MODEL_MASTER/ASICS.md
- specs/MODEL_MASTER/PUMA.md

確認内容:

- 旧誤記の説明文が残っていないか
- 監査メモが現在の内容と矛盾していないか
- モデル候補リスト本体に不要な typo がないか

---

## BLOCKED

### 2026-06-24

以下の作業は GitHub 更新時にブロックされたため、再確認対象として残す。

- specs/MODEL_MASTER/AUDIT_STATUS.md の作成
- PUMA.md の監査メモ文言整理
- ASICS.md の監査メモ文言整理
- NEW_BALANCE.md の監査メモ文言整理

---

## IN_PROGRESS

なし

---

## DONE

### Model Master v1.1 Audit Pass

以下は v1.1 監査更新済み。

- specs/MODEL_MASTER/NIKE.md
- specs/MODEL_MASTER/AIR_JORDAN.md
- specs/MODEL_MASTER/ADIDAS.md
- specs/MODEL_MASTER/NEW_BALANCE.md
- specs/MODEL_MASTER/ASICS.md
- specs/MODEL_MASTER/SALOMON.md
- specs/MODEL_MASTER/HOKA.md
- specs/MODEL_MASTER/ON.md
- specs/MODEL_MASTER/PUMA.md
- specs/MODEL_MASTER/CONVERSE.md
- specs/MODEL_MASTER/VANS.md
- specs/MODEL_MASTER/REEBOK.md
- specs/MODEL_MASTER/ONITSUKA_TIGER.md
- specs/MODEL_MASTER/MIZUNO.md
- specs/MODEL_MASTER/SAUCONY.md
- specs/MODEL_MASTER/BROOKS.md
- specs/MODEL_MASTER/MERRELL.md
- specs/MODEL_MASTER/KEEN.md
- specs/MODEL_MASTER/DANNER.md

---

## Next Audit Set

次に監査する候補。

- specs/MODEL_MASTER/KARHU.md
- specs/MODEL_MASTER/DIADORA.md
- specs/MODEL_MASTER/PATRICK.md
- specs/MODEL_MASTER/K_SWISS.md
- specs/MODEL_MASTER/LE_COQ_SPORTIF.md
- specs/MODEL_MASTER/LACOSTE.md
- specs/MODEL_MASTER/MOONSTAR.md
- specs/MODEL_MASTER/SPINGLE.md

---

## Quality Rule

各ブランドは、ブランド名だけでは完了扱いにしない。

最低限、以下を満たすこと。

- 代表モデルが入っている
- ユーザーが検索しそうな別名候補がある
- 候補にない場合も自由入力できる前提を維持する
- 監査後にこのファイルの状態を更新する
