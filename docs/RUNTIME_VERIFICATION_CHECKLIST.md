# SoleMuseum Runtime Verification Checklist

This checklist defines what must be manually verified on a real device or emulator before treating the current build as runtime-verified.

## Scope

Target app state:

- Flutter / Dart
- Material 3
- Riverpod
- sqflite local database
- Local photo storage
- JSON backup and restore

This checklist is for functional verification only. It does not replace UI polish, store review, or monetization testing.

---

## 1. App launch

- [ ] App launches without crash
- [ ] Bottom navigation appears
- [ ] Home tab opens
- [ ] Collection tab opens
- [ ] Settings tab opens
- [ ] Light theme displays correctly
- [ ] Dark theme displays correctly
- [ ] Theme selection persists after app restart

Expected result:

- The app can be opened and navigated without runtime error.

---

## 2. Brand loading

- [ ] Initial brand list loads
- [ ] Sneaker registration screen shows brand dropdown
- [ ] Existing brands such as Nike, Jordan, adidas, New Balance, ASICS are visible

Expected result:

- Brand data is initialized and usable in sneaker registration.

---

## 3. Sneaker registration

Create at least three test sneakers.

Test data example:

1. Nike / Air Max 95 / 27.5 / Black
2. New Balance / 990v6 / 27.0 / Gray
3. adidas / Samba / 26.5 / White

Verify:

- [ ] New sneaker can be registered
- [ ] Brand is required
- [ ] Model name is required
- [ ] Size can be saved
- [ ] Color can be saved
- [ ] Purchase date can be selected
- [ ] Purchase price accepts numbers only
- [ ] Purchase store can be saved
- [ ] Memo can be saved
- [ ] Favorite toggle can be saved

Expected result:

- Registered sneakers appear in Collection and Detail screens.

---

## 4. Collection list

- [ ] Registered sneakers appear in Collection
- [ ] Brand name is displayed correctly
- [ ] Model name is displayed correctly
- [ ] Archive number is displayed in `SM-0001` format
- [ ] Favorite state is visible where applicable
- [ ] Tapping a sneaker opens its detail screen

Expected result:

- Collection can be used as the main sneaker inventory list.

---

## 5. Sneaker detail

For each registered sneaker, verify:

- [ ] Detail screen opens
- [ ] Brand name is correct
- [ ] Model name is correct
- [ ] Archive number is shown
- [ ] Size is shown
- [ ] Color is shown
- [ ] Purchase date is shown
- [ ] Purchase price is shown
- [ ] Purchase store is shown
- [ ] Memo is shown
- [ ] Created / updated information is shown if implemented

Expected result:

- Detail screen represents the saved sneaker data accurately.

---

## 6. Sneaker edit

- [ ] Existing sneaker can be edited
- [ ] Model name update is reflected in detail
- [ ] Size update is reflected in detail
- [ ] Color update is reflected in detail
- [ ] Memo update is reflected in detail
- [ ] Collection list reflects edited data

Expected result:

- Edited sneaker data is persisted and shown consistently.

---

## 7. Photo registration

For one sneaker, add photos for each type.

- [ ] Main photo can be added
- [ ] Gallery photo can be added
- [ ] Box photo can be added
- [ ] Photo picker opens correctly
- [ ] Selected image is copied into app storage
- [ ] Added photo appears on detail screen
- [ ] Main photo appears as the collection thumbnail
- [ ] Home recent section displays the main photo if applicable

Expected result:

- Photos can be registered, stored, and displayed without distortion or crash.

---

## 8. Photo deletion

- [ ] Long-press or delete action for a photo works
- [ ] Confirmation dialog appears
- [ ] Cancel does not delete the photo
- [ ] Confirm deletes the photo from the UI
- [ ] Deleted photo does not reappear after app restart

Expected result:

- Photo deletion removes the photo record and local file when deleting an individual photo.

---

## 9. Sneaker deletion and photo cleanup

Use a sneaker that has at least one photo.

- [ ] Delete confirmation appears
- [ ] Cancel does not delete the sneaker
- [ ] Confirm deletes the sneaker
- [ ] Deleted sneaker disappears from Collection
- [ ] Deleted sneaker disappears from Home sections where applicable
- [ ] Related photo records are removed by database cascade
- [ ] Related local photo files are removed by cleanup logic
- [ ] App does not crash if a photo file is already missing

Expected result:

- Deleting a sneaker cleans up both database records and local photo files.

---

## 10. Favorite

- [ ] Favorite can be turned on from detail or edit screen
- [ ] Favorite can be turned off
- [ ] Favorite state persists after app restart
- [ ] Favorite state is reflected in Collection or Home where applicable

Expected result:

- Favorite state behaves consistently.

---

## 11. MY TOP 5

Prepare at least six sneakers.

- [ ] Sneaker can be added to MY TOP 5
- [ ] Sneaker can be removed from MY TOP 5
- [ ] Up to five sneakers can be selected
- [ ] Sixth sneaker cannot be added when five are already selected
- [ ] TOP 5 section on Home displays selected sneakers
- [ ] TOP 5 survives app restart

Expected result:

- MY TOP 5 behaves as a limited exhibition feature.

---

## 12. Wear history

For at least two sneakers:

- [ ] Today's wear can be recorded from FAB
- [ ] Today's wear can be recorded from detail screen if supported
- [ ] Optional memo can be saved
- [ ] Same sneaker cannot create duplicate wear record for the same date
- [ ] Wear history appears on detail screen
- [ ] Recent wear appears on Home if applicable
- [ ] Wear log can be deleted
- [ ] Wear history survives app restart

Expected result:

- Wear history works as a persistent usage record.

---

## 13. Home screen

- [ ] App concept / museum-style summary is visible
- [ ] Collection count is correct
- [ ] Recently added sneakers are shown
- [ ] Recently worn sneakers are shown if wear history exists
- [ ] MY TOP 5 appears if configured
- [ ] Brand ownership breakdown is shown if implemented
- [ ] Empty state is acceptable when no sneakers exist

Expected result:

- Home works as a museum dashboard rather than only a navigation page.

---

## 14. JSON backup

With multiple sneakers, photos, favorites, TOP 5, and wear history created:

- [ ] Backup file can be created from Settings
- [ ] Share sheet opens
- [ ] JSON file can be saved or shared
- [ ] Backup file name is understandable
- [ ] Backup file can be opened externally as JSON if needed

Expected result:

- Collection data can be exported as a JSON backup.

Current limitation:

- Photo files are not included in JSON backup.

---

## 15. JSON restore

Use a previously created backup file.

- [ ] Restore file picker opens
- [ ] Only JSON file can be selected
- [ ] Destructive restore confirmation appears
- [ ] Cancel does not restore
- [ ] Confirm restores brands, sneakers, favorites, TOP 5, and wear history
- [ ] Collection list updates after restore
- [ ] Home updates after restore
- [ ] Invalid JSON backup is rejected
- [ ] Restore failure does not leave the app in a broken state

Expected result:

- JSON backup restore works for collection data excluding photos.

Current limitation:

- Restored data does not include photo files.
- Existing local photo files may remain on disk after restore even if DB photo records are cleared.

---

## 16. App restart persistence

After creating realistic data:

- [ ] Close app completely
- [ ] Reopen app
- [ ] Sneakers remain
- [ ] Photos remain
- [ ] Favorites remain
- [ ] MY TOP 5 remains
- [ ] Wear history remains
- [ ] Theme setting remains

Expected result:

- Local persistence works across app restarts.

---

## 17. Edge cases

- [ ] Register sneaker with minimum fields only
- [ ] Register sneaker with all fields filled
- [ ] Long memo does not break layout
- [ ] Very high purchase price does not crash UI
- [ ] Multiple photos do not break detail layout
- [ ] Deleting the last sneaker returns to a clean empty state
- [ ] Backup with no sneakers works or shows a reasonable result
- [ ] Restore with empty backup works or shows a reasonable result

Expected result:

- App handles normal edge cases without crash.

---

## 18. Known limitations before public release

These are not blockers for internal testing, but should be addressed before public release.

- [ ] Photo files are not included in backup
- [ ] Restore does not clean up orphaned local photo files
- [ ] Pro plan / free limits are not implemented
- [ ] Store-ready screenshots are not prepared
- [ ] Store description is not prepared
- [ ] App icon and splash need final review
- [ ] Real device QA has not been completed

---

## Verification result

Fill this section after testing.

- Device:
- OS version:
- App build:
- Tester:
- Date:

Result:

- [ ] Pass
- [ ] Pass with issues
- [ ] Fail

Notes:

-
