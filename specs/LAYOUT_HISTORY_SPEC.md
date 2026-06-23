# Layout Movement History Specification v1.0

## Purpose

Kick×Kick will allow users to move sneakers in Collection display modes.

The app must remember where the user placed each sneaker so the layout feels personal and persistent.

This applies to:

- Shelf mode
- Sticker mode
- Future free placement mode

---

## Core Concept

The user does not only register sneakers.

The user arranges them.

The arrangement itself is part of the collection.

---

## Layout Modes

### List Mode

Management-oriented mode.

Movement history is not required at first.

### Shelf Mode

Sneakers are arranged on shelves.

The app should save:

- Shelf row
- Position in row
- Manual order

### Sticker Mode

Sneakers are displayed like stickers.

The app should save:

- X position
- Y position
- Z order
- Rotation
- Scale

Overlap is allowed.

Overlap is part of the play experience.

---

## Latest Layout State

First implementation should save only the latest position.

Recommended table:

```sql
CREATE TABLE collection_layouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shoe_id INTEGER NOT NULL,
  layout_mode TEXT NOT NULL,
  x_position REAL NOT NULL DEFAULT 0,
  y_position REAL NOT NULL DEFAULT 0,
  z_index INTEGER NOT NULL DEFAULT 0,
  rotation REAL NOT NULL DEFAULT 0,
  scale REAL NOT NULL DEFAULT 1,
  shelf_row INTEGER,
  shelf_column INTEGER,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE,
  UNIQUE(shoe_id, layout_mode)
);
```

---

## Movement History

Later, the app should also save movement events.

This enables:

- Undo
- Restore previous layout
- Replay movement history
- Debugging layout behavior

Future table:

```sql
CREATE TABLE collection_layout_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shoe_id INTEGER NOT NULL,
  layout_mode TEXT NOT NULL,
  from_x REAL,
  from_y REAL,
  to_x REAL,
  to_y REAL,
  from_z_index INTEGER,
  to_z_index INTEGER,
  moved_at TEXT NOT NULL,
  FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
);
```

---

## Sticker Stacking Rules

- Stickers may overlap
- A touched sticker can be brought to the front
- Moving a top sticker may reveal lower stickers
- New z_index must be saved
- Search/filter can reduce overlap temporarily

---

## Shelf Rules

- Sneakers should align to shelf slots
- User can reorder sneakers
- User can move sneakers between shelf rows
- New shelf position must be saved

---

## Priority

### Phase 1

Save latest layout state.

### Phase 2

Support manual movement in Sticker Mode.

### Phase 3

Support manual order in Shelf Mode.

### Phase 4

Save movement event history.

### Phase 5

Add Undo / Restore layout.

---

## Definition of Done

This feature is complete when:

- User can move sneakers in Sticker Mode
- User can move sneakers in Shelf Mode
- Layout is restored after app restart
- Z-order is saved when stickers overlap
- Latest position is stored per sneaker and layout mode
