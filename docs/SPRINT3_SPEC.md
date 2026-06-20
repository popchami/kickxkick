Sprint3 Specification

Sprint Name

Exhibition Foundation

---

Objective

Sprint3 の目的は、SoleMuseum を単なるスニーカー管理アプリから、スニーカーを展示できるデジタルミュージアムへ進化させることである。

ユーザーは所有するスニーカーに写真を追加し、コレクションとして閲覧できるようになる。

---

Goals

Sprint3 完了時点で以下を実現する。

- メイン写真登録
- ギャラリー写真登録
- 箱写真登録
- Collection画面でのサムネイル表示
- Detail画面でのギャラリー表示

---

Database Changes

Database Version:

1 → 2

photos

Column| Type| Required
id| INTEGER| YES
shoe_id| INTEGER| YES
photo_type| TEXT| YES
file_path| TEXT| YES
display_order| INTEGER| YES
created_at| TEXT| YES

---

Photo Types

main

メイン展示写真

Collection画面で表示する写真

---

gallery

追加写真

Detail画面で表示する写真

---

box

箱写真

Detail画面で表示する写真

---

Models

Photo

Properties:

- id
- shoeId
- photoType
- filePath
- displayOrder
- createdAt

---

Repository

PhotoRepository

Functions:

- getPhotosByShoeId()
- getMainPhoto()
- insertPhoto()
- updatePhoto()
- deletePhoto()
- deletePhotosByShoeId()

---

Providers

photoRepositoryProvider

Repository access provider

photosByShoeIdProvider

Photo list provider

mainPhotoProvider

Main photo provider

---

Local Storage

Photos are stored inside the application documents directory.

Structure:

solemuseum/
photos/
shoe_id/

Example:

solemuseum/photos/15/

---

Collection Screen

Without Photo

Display placeholder image.

With Photo

Display main photo.

---

Shoe Detail Screen

Display:

- Main Photo
- Gallery Photos
- Box Photos

Actions:

- Add Main Photo
- Add Gallery Photo
- Add Box Photo

---

Supported Actions

Add Photo

Source:

- Gallery

Delete Photo

User can delete stored photos.

---

Out of Scope

The following features are excluded from Sprint3.

- SNS sharing
- Cloud sync
- Firebase
- AI recognition
- Video support
- Backup
- Wear history
- Market price tracking

---

Completion Criteria

Sprint3 is complete when:

- Photo model exists
- Photos table exists
- Migration works
- User can add photos
- User can view photos
- Collection thumbnail works
- Detail gallery works

---

Success Definition

A user can:

1. Register a sneaker
2. Add photos
3. Open Collection
4. View photo thumbnails
5. Open Detail
6. Browse photo gallery

At this point SoleMuseum becomes a digital sneaker museum rather than a simple inventory application.
