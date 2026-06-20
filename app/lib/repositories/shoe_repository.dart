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
    return db.delete(
      'shoes',
      where: 'id = ?',
      whereArgs: [id],
    );
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
}
