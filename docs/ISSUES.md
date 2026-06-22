SoleMuseum Open Issues

This document tracks known issues, technical debt, future improvements, and unresolved questions.

---

ISSUE-001

Title

Sprint2 Runtime Verification Not Completed

Priority

High

Status

Open

Description

Sprint2 has completed code review.

Runtime verification has not yet been completed.

Required:

- flutter pub get
- flutter analyze
- flutter run

---

ISSUE-002

Title

Photo Deletion UX

Priority

Medium

Status

Planned

Description

Sprint3 supports photo storage.

Photo deletion flow must be designed.

Questions:

- Confirmation dialog?
- Delete file immediately?
- Delete metadata only?

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

Open

Description

Sprint5 introduces MY TOP 5.

Open questions:

- Manual selection?
- Automatic ranking?
- Drag and drop ordering?

Current assumption:

Manual selection.

---

ISSUE-006

Title

Backup Format

Priority

Medium

Status

Open

Description

Sprint6 introduces backup.

Questions:

- JSON only?
- ZIP package?
- Include photos?

Current decision:

JSON first.

ZIP deferred.

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

Open

Description

Still required:

- App icon
- Splash screen
- Screenshots
- Feature graphic

---

ISSUE-010

Title

First Public Release

Priority

High

Status

Open

Description

Requirements:

- Sprint3 complete
- Sprint4 complete
- Sprint5 complete
- Critical bugs fixed

Goal:

SoleMuseum v1.0 release.
