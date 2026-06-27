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
    final path = join(dbPath, 'kickxkick.db');

    return openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
        display_title TEXT,
        sticker_text TEXT,
        status TEXT NOT NULL DEFAULT 'new',
        size TEXT,
        color TEXT,
        purchase_date TEXT,
        purchase_price INTEGER,
        purchase_store TEXT,
        memo TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        top_order INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (brand_id) REFERENCES brands(id)
      )
    ''');

    await _createShoeIndexes(db);
    await _createPhotosTable(db);
    await _createWearLogsTable(db);
    await _insertInitialBrands(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhotosTable(db);
    }
    if (oldVersion < 3) {
      await _createWearLogsTable(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE shoes ADD COLUMN top_order INTEGER');
      await _createTopOrderIndex(db);
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE shoes ADD COLUMN display_title TEXT');
      await db.execute('ALTER TABLE shoes ADD COLUMN sticker_text TEXT');
      await db.execute("ALTER TABLE shoes ADD COLUMN status TEXT NOT NULL DEFAULT 'new'");
    }
    if (oldVersion < 6) {
      await _deduplicateWearLogs(db);
      await _createWearLogDateIndex(db);
    }
    if (oldVersion < 7) {
      await _migratePhotosTable(db);
    }
  }

  Future<void> _createShoeIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shoes_brand_id ON shoes(brand_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shoes_created_at ON shoes(created_at)');
    await _createTopOrderIndex(db);
  }

  Future<void> _createTopOrderIndex(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shoes_top_order ON shoes(top_order)');
  }

  Future<void> _createPhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shoe_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        photo_type TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_photos_shoe_id ON photos(shoe_id)');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_photos_shoe_type ON photos(shoe_id, photo_type)');
  }

  Future<void> _migratePhotosTable(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(photos)');
    final names = columns.map((column) => column['name'] as String).toSet();
    if (names.contains('photo_type') && names.contains('display_order')) {
      return;
    }

    await db.execute('DROP INDEX IF EXISTS idx_photos_shoe_id');
    await db.execute('DROP INDEX IF EXISTS idx_photos_shoe_type');
    await db.execute('''
      CREATE TABLE photos_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shoe_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        photo_type TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');

    if (names.contains('type')) {
      await db.execute('''
        INSERT INTO photos_new (id, shoe_id, file_path, photo_type, display_order, created_at)
        SELECT id, shoe_id, file_path, type, 0, created_at
        FROM photos
      ''');
    } else {
      await db.execute('''
        INSERT INTO photos_new (id, shoe_id, file_path, photo_type, display_order, created_at)
        SELECT id, shoe_id, file_path, 'main', 0, created_at
        FROM photos
      ''');
    }

    await db.execute('DROP TABLE photos');
    await db.execute('ALTER TABLE photos_new RENAME TO photos');
    await _createPhotosTable(db);
  }

  Future<void> _createWearLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wear_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shoe_id INTEGER NOT NULL,
        worn_date TEXT NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wear_logs_shoe_id ON wear_logs(shoe_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wear_logs_worn_date ON wear_logs(worn_date)');
    await _createWearLogDateIndex(db);
  }

  Future<void> _createWearLogDateIndex(Database db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_wear_logs_shoe_date ON wear_logs(shoe_id, worn_date)',
    );
  }

  Future<void> _deduplicateWearLogs(Database db) async {
    await db.execute('''
      DELETE FROM wear_logs
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM wear_logs
        GROUP BY shoe_id, worn_date
      )
    ''');
  }

  Future<void> _insertInitialBrands(Database db) async {
    final brands = [
      'Nike',
      'Adidas',
      'New Balance',
      'ASICS',
      'PUMA',
      'Converse',
      'Vans',
      'Reebok',
      'Other',
    ];

    for (var i = 0; i < brands.length; i++) {
      await db.insert('brands', {
        'name': brands[i],
        'sort_order': i,
      });
    }
  }
}
