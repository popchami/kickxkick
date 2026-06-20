import '../database/app_database.dart';
import '../models/brand.dart';

class BrandRepository {
  Future<List<Brand>> getAllBrands() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'brands',
      orderBy: 'sort_order ASC',
    );
    return maps.map(Brand.fromMap).toList();
  }

  Future<Brand?> getBrandById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'brands',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Brand.fromMap(maps.first);
  }
}
