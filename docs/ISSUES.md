# Kick×Kick Open Issues

This document tracks known issues, technical debt, future improvements, and unresolved questions.

---

## ISSUE-001: Runtime Verification

Priority: High

Status: Open

Sprint1-6 code is merged. Runtime verification on a physical device is required before v1.0 release.

Required:

- flutter pub get
- flutter analyze
- flutter run on Android device
- Verify all 5 screens render correctly
- Verify CRUD operations end-to-end
- Verify data persistence across app restarts
- Verify photo add / delete flow
- Verify backup export and import
- Verify dark mode

---

## ISSUE-002: Photo Deletion UX

Priority: Medium

Status: Resolved

Decision:

- Confirmation dialog: Yes
- Main photo: long-press to trigger deletion dialog
- Gallery/box photos: long-press on thumbnail to trigger deletion dialog
- Delete metadata and file together
- UI hint chip displayed on main photo

---

## ISSUE-003: Collection Performance

Priority: Medium

Status: Future

Large collections may require optimization.

Potential solutions:

- Thumbnail cache
- Query optimization
- Lazy loading

---

## ISSUE-004: Wear Log Data Model

Priority: Medium

Status: Resolved

Decision:

- One entry per shoe per day
- Duplicate records for the same shoe and date are ignored
- Notes are optional
- Records are stored locally in SQLite

---

## ISSUE-005: TOP5 Selection Method

Priority: Low

Status: Resolved

Decision:

- Selection is manual from the shoe detail screen
- A maximum of five shoes can be selected
- Display order follows selection order
- Drag and drop ordering is deferred

---

## ISSUE-006: Backup Format

Priority: Medium

Status: Resolved

Decision:

- v1 uses JSON files
- Brands, shoes, wear history, and TOP5 are included
- Restore replaces existing collection data after confirmation
- ZIP backup with photos is deferred

---

## ISSUE-007: Brand / Model Management

Priority: High

Status: In Progress

Current direction:

- Brand candidates are provided by official master data
- Model candidates will be added by brand
- Free input fallback is required
- Alias support is planned for search quality

Important specs:

```text
specs/BRAND_MASTER.md
specs/KICKXKICK_BRAND_MODEL_CATALOG.md
specs/KICKXKICK_DATA.md
specs/KICKXKICK_DB_SPEC.md
```

---

## ISSUE-008: Cloud Sync Strategy

Priority: Low

Status: Deferred

Deferred until after v1.0.

Potential options:

- Google Drive
- Local export/import
- Other sync strategy

---

## ISSUE-009: App Store Assets

Priority: Medium

Status: In Progress

Still required:

- Run launcher icon generator
- Run splash generator
- App Store / Play Store screenshots
- Play Store feature graphic
- App description localization

---

## ISSUE-010: First Public Release

Priority: High

Status: In Progress

Remaining before release:

- Device runtime verification
- Generate final icon and splash assets
- Android release build
- Performance check
- Store submission

Goal:

Kick×Kick v1.0 release.
