import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/shoe.dart';

class ShoeRepository {
  Future<List<Shoe>> getAllShoes() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'shoes',
      orderBy: 'created_at DESC',
    );
    return maps.map(Shoe.fromMap).toList();
  }

  Future<Shoe?> getShoeById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'shoes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Shoe.fromMap(maps.first);
  }

  Future<int> insertShoe(Shoe shoe) async {
    final db = await AppDatabase.instance.database;
    return db.insert('shoes', shoe.toMap()..remove('id'));
  }

  Future<int> updateShoe(Shoe shoe) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'shoes',
      shoe.copyWith(updatedAt: DateTime.now()).toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [shoe.id],
    );
  }

  Future<int> deleteShoe(int id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.transaction((txn) async {
      final rows = await txn.query(
        'photos',
        columns: ['file_path'],
        where: 'shoe_id = ?',
        whereArgs: [id],
      );

      final deletedCount = await txn.delete(
        'shoes',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _reorderTopFive(txn);
      return (photoRows: rows, deletedCount: deletedCount);
    });

    for (final row in result.photoRows) {
      final filePath = row['file_path'] as String?;
      if (filePath == null || filePath.isEmpty) {
        continue;
      }
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // The database delete has already succeeded. A missing or locked file
        // should not make shoe deletion fail from the user's perspective.
      }
    }

    return result.deletedCount;
  }

  Future<bool> setTopFive(int id, bool selected) async {
    final db = await AppDatabase.instance.database;

    if (!selected) {
      return db.transaction((txn) async {
        final updated = await txn.update(
          'shoes',
          {
            'top_order': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _reorderTopFive(txn);
        return updated > 0;
      });
    }

    final countRows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM shoes WHERE top_order IS NOT NULL',
    );
    final count = countRows.first['count'] as int? ?? 0;
    if (count >= 5) {
      return false;
    }

    final maxRows = await db.rawQuery(
      'SELECT MAX(top_order) AS max_order FROM shoes',
    );
    final maxOrder = maxRows.first['max_order'] as int? ?? 0;
    final updated = await db.update(
      'shoes',
      {
        'top_order': maxOrder + 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  Future<void> setTopOrder(int shoeId, int rank) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final currentRows = await txn.query(
        'shoes',
        columns: ['top_order'],
        where: 'id = ?',
        whereArgs: [shoeId],
        limit: 1,
      );
      final previousRank = currentRows.isEmpty
          ? null
          : currentRows.first['top_order'] as int?;
      final occupiedRows = await txn.query(
        'shoes',
        columns: ['id'],
        where: 'top_order = ? AND id != ?',
        whereArgs: [rank, shoeId],
        limit: 1,
      );
      if (occupiedRows.isNotEmpty) {
        await txn.update(
          'shoes',
          {'top_order': previousRank},
          where: 'id = ?',
          whereArgs: [occupiedRows.first['id']],
        );
      }
      await txn.update(
        'shoes',
        {
          'top_order': rank,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [shoeId],
      );
    });
  }

  Future<void> _reorderTopFive(DatabaseExecutor db) async {
    final rows = await db.query(
      'shoes',
      columns: ['id'],
      where: 'top_order IS NOT NULL',
      orderBy: 'top_order ASC, updated_at ASC',
    );
    for (var i = 0; i < rows.length; i++) {
      await db.update(
        'shoes',
        {'top_order': i + 1},
        where: 'id = ?',
        whereArgs: [rows[i]['id']],
      );
    }
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'shoes',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markWornIfNew(int id) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'shoes',
      {
        'status': Shoe.statusWorn,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [id, Shoe.statusNew],
    );
  }
}
