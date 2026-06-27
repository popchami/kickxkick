import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/sticker_asset.dart';

class StickerRepository {
  Future<List<StickerAsset>> getStickers() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('stickers', orderBy: 'created_at DESC');
    return rows.map(StickerAsset.fromMap).toList();
  }

  Future<int> saveSticker({required int shoeId, required String sourcePath, required String stickerPath}) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'stickers',
      {'shoe_id': shoeId, 'source_path': sourcePath, 'sticker_path': stickerPath, 'created_at': now, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final row = await db.query('stickers', columns: ['id'], where: 'shoe_id = ?', whereArgs: [shoeId], limit: 1);
    return row.first['id'] as int;
  }

  Future<int> ensureDefaultBoard() async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('sticker_boards', columns: ['id'], limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    final now = DateTime.now().toIso8601String();
    return db.insert('sticker_boards', {'name': 'MY BOARD', 'aspect_ratio': 0.8, 'created_at': now, 'updated_at': now});
  }

  Future<List<StickerBoardItem>> getBoardItems(int boardId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('sticker_board_items', where: 'board_id = ?', whereArgs: [boardId], orderBy: 'z_index');
    return rows.map(StickerBoardItem.fromMap).toList();
  }

  Future<void> addToBoard(int boardId, int stickerId) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('sticker_board_items', where: 'board_id = ? AND sticker_id = ?', whereArgs: [boardId, stickerId], limit: 1);
    if (existing.isNotEmpty) return;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sticker_board_items WHERE board_id = ?', [boardId])) ?? 0;
    await db.insert('sticker_board_items', {'board_id': boardId, 'sticker_id': stickerId, 'x': 0.12 + (count % 3) * 0.25, 'y': 0.12 + (count ~/ 3) * 0.25, 'scale': 1.0, 'rotation': 0.0, 'z_index': count});
  }

  Future<void> updateBoardItem(StickerBoardItem item) async {
    final db = await AppDatabase.instance.database;
    await db.update('sticker_board_items', {'x': item.x, 'y': item.y, 'scale': item.scale, 'rotation': item.rotation, 'z_index': item.zIndex}, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<StickerBoardItem> duplicateBoardItem(StickerBoardItem source) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('sticker_board_items', {
      'board_id': source.boardId,
      'sticker_id': source.stickerId,
      'x': (source.x + .05).clamp(0, .78),
      'y': (source.y + .05).clamp(0, .82),
      'scale': source.scale,
      'rotation': source.rotation,
      'z_index': source.zIndex + 1,
    });
    return StickerBoardItem(
      id: id,
      boardId: source.boardId,
      stickerId: source.stickerId,
      x: (source.x + .05).clamp(0, .78),
      y: (source.y + .05).clamp(0, .82),
      scale: source.scale,
      rotation: source.rotation,
      zIndex: source.zIndex + 1,
    );
  }

  Future<void> deleteBoardItem(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('sticker_board_items', where: 'id = ?', whereArgs: [id]);
  }
}
