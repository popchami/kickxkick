import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'solemuseum.db');

    return openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_id INTEGER NOT NULL,
        model_name TEXT NOT NULL,
        size TEXT,
        color TEXT,
        purchase_date TEXT,
        purchase_price INTEGER,
        purchase_store TEXT,
        memo TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (brand_id) REFERENCES brands(id)
      )
    ''');

    await _createShoeIndexes(db);
    await _createPhotosTable(db);
    await _insertInitialBrands(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhotosTable(db);
    }
  }

  Future<void> _createShoeIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_shoes_brand_id ON shoes(brand_id)');
    await db.execute('CREATE INDEX idx_shoes_created_at ON shoes(created_at)');
    await db.execute('CREATE INDEX idx_shoes_is_favorite ON shoes(is_favorite)');
  }

  Future<void> _createPhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shoe_id INTEGER NOT NULL,
        photo_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_photos_shoe_id ON photos(shoe_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_photos_photo_type ON photos(photo_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_photos_display_order ON photos(display_order)',
    );
  }

  Future<void> _insertInitialBrands(Database db) async {
    const brands = [
      'Nike',
      'Jordan',
      'adidas',
      'New Balance',
      'ASICS',
      'PUMA',
      'Converse',
      'Vans',
      'Reebok',
      'Mizuno',
      'On',
      'HOKA',
      'Salomon',
      'Saucony',
      'Y-3',
      'その他',
    ];

    for (var i = 0; i < brands.length; i++) {
      await db.insert(
        'brands',
        {
          'name': brands[i],
          'sort_order': i + 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
