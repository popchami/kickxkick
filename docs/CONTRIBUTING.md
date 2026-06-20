SoleMuseum Contributing Guide

Purpose

This document defines the development rules for SoleMuseum.

All contributors, AI assistants, and future developers should follow these guidelines.

---

Development Philosophy

SoleMuseum is a digital sneaker museum.

The goal is:

- Collect
- Record
- Exhibit

The goal is NOT:

- Marketplace
- Auction platform
- Social network

---

Priority Order

Always prioritize:

1. Stability
2. Data safety
3. Simplicity
4. User experience
5. New features

Never sacrifice stability for new functionality.

---

MVP Rule

Before v1.0 release:

Do not add features outside the roadmap.

Allowed:

- Sprint1
- Sprint2
- Sprint3
- Sprint4
- Sprint5

Not allowed:

- Cloud sync
- AI features
- Social sharing
- Premium subscriptions
- Marketplace integration

---

Architecture Rule

UI must not directly access SQLite.

Correct flow:

UI

↓

Provider

↓

Repository

↓

Database

---

Database Rule

All schema changes must:

1. Increase database version
2. Provide migration logic
3. Preserve existing user data

Data loss is never acceptable.

---

State Management Rule

Use Riverpod.

Avoid:

- Global variables
- Singleton state
- Direct widget state sharing

---

UI Rule

Use Material 3.

Requirements:

- Loading states
- Empty states
- Error states

Every screen should handle all three.

---

Photo Rule

Photo files must be stored locally.

Database stores only:

- file_path
- metadata

Do not store image binaries in SQLite.

---

Naming Rule

Files:

snake_case

Examples:

- shoe_repository.dart
- photo_provider.dart

Classes:

PascalCase

Examples:

- ShoeRepository
- PhotoStorageService

---

Feature Development Process

Before implementation:

1. Roadmap update
2. Specification update

After implementation:

1. Code review
2. Runtime verification
3. Documentation update

---

Code Quality Rule

Every new feature should:

- Compile successfully
- Pass flutter analyze
- Avoid warnings when possible

---

Release Rule

No new feature ideas after Sprint5 begins.

Focus on:

- Bug fixes
- Stability
- Release preparation

---

Definition of Success

A collector can preserve their sneaker collection for years without depending on external services.

Every decision should support that goal.
