# SoleMuseum Roadmap v1.0

## v1.0 Goal

SoleMuseum v1.0 は、スニーカーを「収蔵・記録・展示」できるデジタルミュージアムとして成立することを目標とする。

---

## Sprint1: App Foundation

Status: Completed

- Flutter app foundation
- Material 3 theme
- Riverpod setup
- Bottom navigation
- Home screen
- Collection screen
- Settings screen
- Shared FAB

---

## Sprint2: Collection CRUD

Status: Code Review Completed

- SQLite database
- Brand model
- Shoe model
- Brand repository
- Shoe repository
- Riverpod providers
- Shoe registration
- Shoe list
- Shoe detail
- Shoe edit
- Shoe delete
- Favorite toggle

Remaining:

- flutter pub get
- flutter analyze
- flutter run

---

## Sprint3: Exhibition Foundation

Status: Planned

Purpose:

- Turn SoleMuseum from a simple management app into a digital sneaker museum.

Scope:

- Photo model
- Photos table
- Photo repository
- Photo provider
- Image picker
- Local photo storage
- Main photo
- Gallery photos
- Box photos
- Collection thumbnail display
- Detail gallery display

Out of scope:

- SNS sharing
- Cloud sync
- AI recognition
- Backup
- Pro purchase
- Wear logs

---

## Sprint4: History Foundation

Status: Planned

Scope:

- Wear log model
- wear_logs table
- Today worn action
- Wear history on detail screen
- Recent worn section on home screen

---

## Sprint5: Museum Home

Status: Planned

Scope:

- MY TOP 5
- Recently added
- Recently worn
- Collection summary
- Brand ownership summary

---

## Sprint6: Backup Foundation

Status: Planned

Scope:

- JSON export
- JSON import
- Local backup
- Restore confirmation

ZIP backup is deferred.

---

## Frozen Until After v1.0

The following features are intentionally deferred:

- Cloud sync
- Firebase
- Login
- SNS sharing
- AI appraisal
- Market price tracking
- Release notifications
- Pro subscription
- Multi-device sync

---

## v1.0 Completion Criteria

SoleMuseum v1.0 is complete when the following are available:

### Collect

- Add shoes
- Edit shoes
- Delete shoes
- View collection

### Exhibit

- Main photo
- Gallery photos
- MY TOP 5

### Record

- Today worn
- Wear history

---

## Development Principle

Do not add new feature ideas until Sprint5 is complete.

Priority order:

1. Finish Sprint2 verification
2. Implement Sprint3 photos
3. Implement Sprint4 wear history
4. Implement Sprint5 museum home
5. Prepare v1.0 release
