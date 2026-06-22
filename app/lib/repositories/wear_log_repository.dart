import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/wear_log.dart';

class WearLogRepository {
  Future<List<WearLog>> getWearLogsByShoeId(int shoeId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'wear_logs',
      where: 'shoe_id = ?',
      whereArgs: [shoeId],
      orderBy: 'worn_date DESC, created_at DESC',
    );
    return maps.map(WearLog.fromMap).toList();
  }

  Future<List<WearLog>> getAllWearLogs() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'wear_logs',
      orderBy: 'worn_date DESC, created_at DESC',
    );
    return maps.map(WearLog.fromMap).toList();
  }

  Future<List<WearLog>> getRecentWearLogs({int limit = 10}) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'wear_logs',
      orderBy: 'worn_date DESC, created_at DESC',
      limit: limit,
    );
    return maps.map(WearLog.fromMap).toList();
  }

  Future<int> updateWearLogMemo(int id, String? memo) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'wear_logs',
      {'memo': memo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> insertWearLog(WearLog wearLog) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert(
      'wear_logs',
      wearLog.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id != 0;
  }

  Future<int> deleteWearLog(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'wear_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWearLogsByShoeId(int shoeId) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'wear_logs',
      where: 'shoe_id = ?',
      whereArgs: [shoeId],
    );
  }
}
