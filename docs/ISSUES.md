SoleMuseum Open Issues

This document tracks known issues, technical debt, future improvements, and unresolved questions.

---

ISSUE-001

Title

Runtime Verification (All Sprints)

Priority

High

Status

Open

Description

Sprint1-6 code is merged. Runtime verification on a physical device
is required before v1.0 release.

Required:

- flutter pub get (pubspec.lock refresh after dependency changes)
- flutter analyze (zero warnings target)
- flutter run on Android device
- Verify all 5 screens render correctly
- Verify CRUD operations end-to-end
- Verify data persistence across app restarts
- Verify photo add / delete flow
- Verify backup export and import
- Verify dark mode

---

ISSUE-002

Title

Photo Deletion UX

Priority

Medium

Status

Resolved

Decision

- Confirmation dialog: Yes (AlertDialog with "キャンセル" / "削除")
- Main photo: long-press to trigger deletion dialog
- Gallery/box photos: long-press on thumbnail to trigger deletion dialog
- Delete metadata and file simultaneously via transaction
- UI hint chip ("長押しで削除") displayed on main photo

---

ISSUE-003

Title

Collection Performance

Priority

Medium

Status

Future

Description

Collection screen currently loads photo data per shoe.

Large collections may require optimization.

Potential solutions:

- Thumbnail cache
- Query optimization
- Lazy loading

---

ISSUE-004

Title

Wear Log Data Model

Priority

Medium

Status

Resolved

Decision

- One entry per shoe per day
- Duplicate records for the same shoe and date are ignored
- Notes are optional
- Records are stored locally in SQLite

---

ISSUE-005

Title

Top 5 Selection Method

Priority

Low

Status

Resolved

Decision

- Selection is manual from the shoe detail screen
- A maximum of five shoes can be selected
- Display order follows selection order
- Favorites remain a separate feature
- Drag and drop ordering is deferred

---

ISSUE-006

Title

Backup Format

Priority

Medium

Status

Resolved

Decision

- v1 uses JSON files
- Brands, shoes, wear history, favorites, and MY TOP 5 are included
- Photo files and photo metadata are not included
- Restore replaces existing collection data after confirmation
- ZIP backup with photos is deferred

---

ISSUE-007

Title

Brand Management

Priority

Low

Status

Future

Description

Current brands are seeded.

Future consideration:

- Add custom brands
- Edit brands
- Hide brands

Not required for v1.0.

---

ISSUE-008

Title

Cloud Sync Strategy

Priority

Low

Status

Deferred

Description

Deferred until after v1.0.

Potential options:

- Firebase
- Google Drive
- Self-hosted sync

---

ISSUE-009

Title

App Store Assets

Priority

Medium

Status

In Progress

Description

Progress:

- App icon: asset created (assets/icon/icon.png 1024x1024, Museum Black + Gallery Gold "S")
- Adaptive icon foreground: created (assets/icon/icon_foreground.png)
- Splash logo: created (assets/splash/splash_logo.png)
- flutter_launcher_icons: configured in pubspec.yaml
- flutter_native_splash: configured in pubspec.yaml

Still required (needs Flutter SDK):

- Run: flutter pub run flutter_launcher_icons
- Run: flutter pub run flutter_native_splash:create
- App Store / Play Store screenshots (5 screens minimum)
- Play Store feature graphic (1024x500)
- App description localization

---

ISSUE-010

Title

First Public Release

Priority

High

Status

In Progress

Description

Code status:

- Sprint1-6: merged to main
- Analyzer: zero warnings (CI green on Flutter 3.24.x, updated to stable)
- Release assets: icon + splash configured

Remaining before release:

- ISSUE-001: Device runtime verification
- ISSUE-009: Run launcher_icons + native_splash generators, take screenshots
- Android release build (flutter build apk --release)
- Performance check (list load <3s, detail <1s)
- Play Store / App Store submission

Goal:

SoleMuseum v1.0 release.
