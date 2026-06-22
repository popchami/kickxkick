import '../database/app_database.dart';
import '../models/photo.dart';

class PhotoRepository {
  Future<List<Photo>> getPhotosByShoeId(int shoeId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'photos',
      where: 'shoe_id = ?',
      whereArgs: [shoeId],
      orderBy: 'display_order ASC, created_at ASC',
    );
    return maps.map(Photo.fromMap).toList();
  }

  Future<Photo?> getMainPhoto(int shoeId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'photos',
      where: 'shoe_id = ? AND photo_type = ?',
      whereArgs: [shoeId, PhotoType.main.databaseValue],
      orderBy: 'display_order ASC, created_at ASC',
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Photo.fromMap(maps.first);
  }

  Future<int> insertPhoto(Photo photo) async {
    final db = await AppDatabase.instance.database;
    return db.insert('photos', photo.toMap()..remove('id'));
  }

  Future<int> updatePhoto(Photo photo) async {
    final id = photo.id;
    if (id == null) {
      throw ArgumentError('Photo id is required for update.');
    }

    final db = await AppDatabase.instance.database;
    return db.update(
      'photos',
      photo.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setAsMainPhoto(int photoId, int shoeId) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'photos',
        {'photo_type': PhotoType.gallery.databaseValue},
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [shoeId, PhotoType.main.databaseValue],
      );
      await txn.update(
        'photos',
        {'photo_type': PhotoType.main.databaseValue},
        where: 'id = ?',
        whereArgs: [photoId],
      );
    });
  }

  Future<int> deletePhoto(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePhotosByShoeId(int shoeId) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'photos',
      where: 'shoe_id = ?',
      whereArgs: [shoeId],
    );
  }
}
