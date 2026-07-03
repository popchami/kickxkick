import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/shelf.dart';

class ShelfRepository {
  static const slotCount = 25;

  Future<List<Shelf>> getShelves() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('shelves', orderBy: 'created_at ASC');
    return rows.map(Shelf.fromMap).toList();
  }

  Future<int> createShelf(String name) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    return db.insert(
      'shelves',
      {'name': name, 'created_at': now, 'updated_at': now},
    );
  }

  Future<List<ShelfItem>> getShelfItems(int shelfId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'shelf_items',
      where: 'shelf_id = ?',
      whereArgs: [shelfId],
      orderBy: 'slot_index ASC',
    );
    return rows.map(ShelfItem.fromMap).toList();
  }

  /// 靴を棚に追加し、0〜24のうち未使用のslot_indexを自動で割り当てる。
  /// 満枠（25個埋まっている）の場合はnullを返す。
  Future<int?> addShoeToShelf(int shelfId, int shoeId) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'shelf_items',
      columns: ['slot_index'],
      where: 'shelf_id = ?',
      whereArgs: [shelfId],
    );
    final usedSlots = existing.map((row) => row['slot_index'] as int).toSet();
    int? freeSlot;
    for (var i = 0; i < slotCount; i++) {
      if (!usedSlots.contains(i)) {
        freeSlot = i;
        break;
      }
    }
    if (freeSlot == null) return null;
    return db.insert('shelf_items', {
      'shelf_id': shelfId,
      'shoe_id': shoeId,
      'slot_index': freeSlot,
    });
  }

  /// 靴を別のスロットへ移動する。移動先が別の靴で埋まっている場合は
  /// スロットを入れ替える（ドラッグでの並べ替えUIとして自然な挙動のため）。
  /// UNIQUE(shelf_id, slot_index)制約に一瞬でも抵触しないよう、
  /// 範囲外の一時スロット(-1)を経由して3段階で入れ替える。
  Future<void> moveShoeSlot(int shelfId, int shoeId, int newSlotIndex) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final currentRows = await txn.query(
        'shelf_items',
        where: 'shelf_id = ? AND shoe_id = ?',
        whereArgs: [shelfId, shoeId],
        limit: 1,
      );
      if (currentRows.isEmpty) return;
      final currentSlot = currentRows.first['slot_index'] as int;
      if (currentSlot == newSlotIndex) return;

      final occupyingRows = await txn.query(
        'shelf_items',
        where: 'shelf_id = ? AND slot_index = ?',
        whereArgs: [shelfId, newSlotIndex],
        limit: 1,
      );

      const tempSlot = -1;
      await txn.update(
        'shelf_items',
        {'slot_index': tempSlot},
        where: 'shelf_id = ? AND shoe_id = ?',
        whereArgs: [shelfId, shoeId],
      );

      if (occupyingRows.isNotEmpty) {
        final occupyingShoeId = occupyingRows.first['shoe_id'] as int;
        await txn.update(
          'shelf_items',
          {'slot_index': currentSlot},
          where: 'shelf_id = ? AND shoe_id = ?',
          whereArgs: [shelfId, occupyingShoeId],
        );
      }

      await txn.update(
        'shelf_items',
        {'slot_index': newSlotIndex},
        where: 'shelf_id = ? AND shoe_id = ?',
        whereArgs: [shelfId, shoeId],
      );
    });
  }

  /// 棚から靴を外す。靴自体やステッカーは削除しない。
  Future<void> removeShoeFromShelf(int shelfId, int shoeId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'shelf_items',
      where: 'shelf_id = ? AND shoe_id = ?',
      whereArgs: [shelfId, shoeId],
    );
  }
}
