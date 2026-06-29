# KickxKick Current Spec Index

Updated: 2026-06-29

## Read Order

1. `KICKXKICK_CURRENT_SPEC_INDEX.md`
2. `CURRENT_STATUS.md`
3. `CHANGELOG.md`
4. `KICKXKICK_MVP_STICKER_COLLECTION_SPEC.md`
5. Implementation code

Sticker / Collectionの正本は `KICKXKICK_MVP_STICKER_COLLECTION_SPEC.md` とする。`CURRENT_STATUS.md` は実装状況のみ、`CHANGELOG.md` は変更時期と内容のみを記録する。

This file is the current entry point for active specs.

## Priority

1. KICKXKICK_MVP_STICKER_COLLECTION_SPEC.md
2. KICKXKICK_SHARED_ASSET_STICKER_STYLE_SPEC.md
3. KICKXKICK_STICKER_BOARD_UPDATE_SPEC.md

## Latest Sticker Board Rules

- Free board limit: 10 stickers
- Premium board limit: 30 stickers
- Old limits 20 and 100 are obsolete
- Board area should use more screen space
- View mode allows moving stickers only
- Edit mode long press opens sticker design editor
- Selected sticker toolbar: paste, duplicate, delete, scale up, scale down, bring front
- No send-to-back action for MVP
- Sticker text should be inside the orange border
- Sticker text supports size and position editing
- Selection frame and handles must follow move, rotate, and scale
- Reduce stored data and rendering load without reducing original image quality

## Rule

When Sticker or Collection specs change, update this file as the latest index.
