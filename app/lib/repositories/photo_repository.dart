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

  Future<List<Photo>> replacePhoto(Photo photo) async {
    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final previousMaps = await txn.query(
        'photos',
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [photo.shoeId, photo.photoType.databaseValue],
      );
      await txn.delete(
        'photos',
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [photo.shoeId, photo.photoType.databaseValue],
      );
      await txn.insert('photos', photo.toMap()..remove('id'));
      return previousMaps.map(Photo.fromMap).toList();
    });
  }

  Future<void> setMainPhoto(Photo selected) async {
    final id = selected.id;
    if (id == null || selected.photoType == PhotoType.main) return;
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final currentMain = await txn.query(
        'photos',
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [selected.shoeId, PhotoType.main.databaseValue],
        limit: 1,
      );
      final temporaryType = 'temporary_main_$id';
      if (currentMain.isNotEmpty) {
        await txn.update(
          'photos',
          {'photo_type': temporaryType},
          where: 'id = ?',
          whereArgs: [currentMain.first['id']],
        );
      }
      await txn.update(
        'photos',
        {'photo_type': PhotoType.main.databaseValue},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (currentMain.isNotEmpty) {
        await txn.update(
          'photos',
          {'photo_type': selected.photoType.databaseValue},
          where: 'id = ?',
          whereArgs: [currentMain.first['id']],
        );
      }
    });
  }

  Future<List<Photo>> replaceMainPhoto(Photo photo) async {
    if (photo.photoType != PhotoType.main) {
      throw ArgumentError('A main photo is required.');
    }

    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final previousMaps = await txn.query(
        'photos',
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [photo.shoeId, PhotoType.main.databaseValue],
      );

      await txn.delete(
        'photos',
        where: 'shoe_id = ? AND photo_type = ?',
        whereArgs: [photo.shoeId, PhotoType.main.databaseValue],
      );
      await txn.insert('photos', photo.toMap()..remove('id'));

      return previousMaps.map(Photo.fromMap).toList();
    });
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
