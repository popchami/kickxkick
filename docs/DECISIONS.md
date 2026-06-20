SoleMuseum Architecture Decisions

This document records major architectural and product decisions.

---

DECISION-001

Title

Offline First Architecture

Status

Accepted

Date

2026-06

Decision

SoleMuseum will function completely offline.

No account is required.

No internet connection is required.

Reason

Collectors should always own their collection data.

The application must continue working even if external services disappear.

Consequences

Positive

- Fast
- Reliable
- No login required
- User owns data

Negative

- Multi-device sync requires future work

---

DECISION-002

Title

SQLite as Primary Database

Status

Accepted

Date

2026-06

Decision

Use SQLite for local storage.

Reason

- Proven technology
- Flutter support
- Offline capable
- Easy backup

Rejected Alternatives

Firebase

Rejected before v1.0.

Reason:

Adds complexity and account requirements.

---

DECISION-003

Title

Museum Before Marketplace

Status

Accepted

Date

2026-06

Decision

Focus on collection preservation rather than buying and selling.

Reason

Most sneaker apps focus on transactions.

SoleMuseum focuses on ownership history and preservation.

Consequences

Features intentionally delayed:

- Marketplace
- Auctions
- Price tracking

---

DECISION-004

Title

Photos Before Wear History

Status

Accepted

Date

2026-06

Decision

Sprint3 implements photos before wear history.

Reason

Photos are essential to the museum concept.

Without photos, the collection cannot be exhibited.

---

DECISION-005

Title

No Cloud Sync Before v1.0

Status

Accepted

Date

2026-06

Decision

Cloud sync is postponed until after v1.0.

Reason

Focus on completing core collector workflows first.

Deferred

- Firebase
- Google Drive sync
- Multi-device sync

---

DECISION-006

Title

Riverpod State Management

Status

Accepted

Date

2026-06

Decision

Use Riverpod as the only state management solution.

Reason

- Scalable
- Testable
- Flutter ecosystem support

Avoid

- Global mutable state
- Multiple state management systems

---

Future Decisions

New decisions should be added using:

DECISION-XXX

Format.

Never modify historical decisions.

Only append new entries.
