# SoleMuseum Runtime Verification Plan

This document turns `docs/RUNTIME_VERIFICATION_CHECKLIST.md` into a practical execution order for smartphone or emulator testing.

Goal:

- Verify the current app can actually be used end to end.
- Find runtime bugs before adding larger features such as photo-inclusive backup or monetization.

---

## Phase 0: Preparation

Before testing:

- [ ] Install or run the latest app build
- [ ] Start with a clean app state if possible
- [ ] Prepare 3 to 6 sneaker examples
- [ ] Prepare at least 3 photos on the device
- [ ] Prepare a place to save/share a JSON backup file

Recommended test data:

1. Nike / Air Max 95 / 27.5 / Black
2. New Balance / 990v6 / 27.0 / Gray
3. adidas / Samba / 26.5 / White
4. ASICS / GEL-KAYANO / 27.0 / Blue
5. Jordan / Air Jordan 1 / 28.0 / Red
6. Converse / Chuck Taylor / 26.5 / Black

---

## Phase 1: Smoke test

Purpose:

Confirm the app starts and basic navigation works.

Steps:

- [ ] Launch the app
- [ ] Open Home
- [ ] Open Collection
- [ ] Open Settings
- [ ] Switch theme to Light
- [ ] Switch theme to Dark
- [ ] Restart the app
- [ ] Confirm selected theme persists

Pass condition:

- No crash
- All main tabs open
- Theme switching works

Stop condition:

- App cannot launch
- Main navigation crashes

---

## Phase 2: Minimum sneaker flow

Purpose:

Confirm the core MVP flow works.

Steps:

- [ ] Register one sneaker with minimum fields
- [ ] Confirm it appears in Collection
- [ ] Open detail screen
- [ ] Confirm archive number appears as `SM-0001` style
- [ ] Edit the sneaker
- [ ] Change model name, size, color, memo
- [ ] Save
- [ ] Confirm detail and collection update

Pass condition:

- One sneaker can be created, viewed, edited, and persisted

Stop condition:

- Registration or detail screen crashes

---

## Phase 3: Collection scale test

Purpose:

Confirm multiple sneakers behave correctly.

Steps:

- [ ] Register at least 6 sneakers
- [ ] Confirm all appear in Collection
- [ ] Confirm archive numbers are unique
- [ ] Open several detail screens
- [ ] Restart app
- [ ] Confirm all data remains

Pass condition:

- Multiple sneakers remain usable after restart

---

## Phase 4: Photo flow

Purpose:

Confirm photo registration and display work.

Steps:

- [ ] Add a main photo to one sneaker
- [ ] Add a gallery photo
- [ ] Add a box photo
- [ ] Confirm photos appear on detail screen
- [ ] Confirm main photo appears in Collection thumbnail
- [ ] Confirm main photo appears on Home where applicable
- [ ] Restart app
- [ ] Confirm photos remain

Pass condition:

- Photos display correctly and persist

Important note:

- Photo backup is not supported yet. This test only checks local photo storage.

---

## Phase 5: Photo deletion and sneaker deletion

Purpose:

Confirm cleanup logic works.

Steps:

- [ ] Delete one individual photo
- [ ] Confirm it disappears
- [ ] Restart app
- [ ] Confirm it does not reappear
- [ ] Delete a sneaker that has photos
- [ ] Confirm the sneaker disappears from Collection
- [ ] Confirm Home no longer shows the deleted sneaker
- [ ] Confirm app does not crash

Pass condition:

- Photo deletion and sneaker deletion both work without stale UI or crash

Known technical expectation:

- Database photo rows are removed by cascade.
- Local photo files are cleaned up by `ShoeRepository.deleteShoe()`.

---

## Phase 6: Favorite and MY TOP 5

Purpose:

Confirm curation features work.

Steps:

- [ ] Mark a sneaker as favorite
- [ ] Remove favorite
- [ ] Add five sneakers to MY TOP 5
- [ ] Try adding a sixth sneaker
- [ ] Confirm sixth sneaker is rejected or not added
- [ ] Confirm TOP 5 appears on Home
- [ ] Restart app
- [ ] Confirm TOP 5 persists

Pass condition:

- Favorite and TOP 5 states persist and respect the five-item limit

---

## Phase 7: Wear history

Purpose:

Confirm wearing records work.

Steps:

- [ ] Record today's wear for one sneaker
- [ ] Add an optional memo
- [ ] Confirm wear history appears on detail
- [ ] Confirm recent wear appears on Home where applicable
- [ ] Try recording the same sneaker again for today
- [ ] Confirm duplicate is not created
- [ ] Delete a wear log
- [ ] Restart app
- [ ] Confirm remaining wear history persists

Pass condition:

- Wear history works as a stable usage log

---

## Phase 8: JSON backup

Purpose:

Confirm data export works.

Steps:

- [ ] Create a backup from Settings
- [ ] Confirm share sheet opens
- [ ] Save or share the JSON file
- [ ] Confirm backup file is created

Pass condition:

- Backup file can be produced and exported

Known limitation:

- Photos are not included in JSON backup.

---

## Phase 9: JSON restore

Purpose:

Confirm destructive restore works.

Recommended setup:

- Create backup after registering sneakers, favorites, TOP 5, and wear history.
- Then add or change data after backup.
- Restore the backup.

Steps:

- [ ] Open restore from Settings
- [ ] Select backup JSON
- [ ] Confirm destructive restore dialog appears
- [ ] Cancel once and confirm no restore occurs
- [ ] Start restore again
- [ ] Confirm restore
- [ ] Confirm Collection updates
- [ ] Confirm Home updates
- [ ] Confirm favorites restore
- [ ] Confirm MY TOP 5 restores
- [ ] Confirm wear history restores

Pass condition:

- JSON restore replaces current collection data with backup data

Known limitation:

- Restored backup does not restore photo files.
- Existing local photo files may remain as orphaned files after restore.

---

## Phase 10: Final restart test

Purpose:

Confirm full app state persists.

Steps:

- [ ] Close the app completely
- [ ] Reopen the app
- [ ] Check Home
- [ ] Check Collection
- [ ] Check Settings
- [ ] Check one sneaker detail
- [ ] Check photos
- [ ] Check TOP 5
- [ ] Check wear history

Pass condition:

- App state is still correct after restart

---

## Result recording

Record results here after testing.

Device:

OS version:

App build:

Tester:

Date:

Overall result:

- [ ] Pass
- [ ] Pass with issues
- [ ] Fail

Issues found:

1.
2.
3.

Next action:

-
