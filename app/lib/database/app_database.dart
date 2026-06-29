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
      version: 12,
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
    await _createSettingsTable(db);
    await _createStickerTables(db);
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
    if (oldVersion < 8) {
      await _createSettingsTable(db);
      await _createStickerTables(db);
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE photos ADD COLUMN cutout_path TEXT');
    }
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE stickers ADD COLUMN sticker_text TEXT');
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN text_color INTEGER NOT NULL DEFAULT 4294928896',
      );
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN inner_border_color INTEGER NOT NULL DEFAULT 4294967295',
      );
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN outer_border_color INTEGER NOT NULL DEFAULT 4294928896',
      );
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN shadow_enabled INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute('''
        UPDATE stickers
        SET sticker_text = (
          SELECT shoes.sticker_text
          FROM shoes
          WHERE shoes.id = stickers.shoe_id
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE stickers ADD COLUMN preview_path TEXT');
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN text_scale REAL NOT NULL DEFAULT 1.0',
      );
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN text_x REAL NOT NULL DEFAULT 0.5',
      );
      await db.execute(
        'ALTER TABLE stickers ADD COLUMN text_y REAL NOT NULL DEFAULT 0.72',
      );
    }
    if (oldVersion < 12) {
      await db.execute(
        'UPDATE stickers SET text_scale = 0.75 WHERE text_scale = 1.0',
      );
      await db.execute(
        'UPDATE stickers SET text_y = 0.55 WHERE text_y = 0.72',
      );
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
        cutout_path TEXT,
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
        cutout_path TEXT,
        photo_type TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');

    if (names.contains('type')) {
      await db.execute('''
        INSERT INTO photos_new (id, shoe_id, file_path, cutout_path, photo_type, display_order, created_at)
        SELECT id, shoe_id, file_path, NULL, type, 0, created_at
        FROM photos
      ''');
    } else {
      await db.execute('''
        INSERT INTO photos_new (id, shoe_id, file_path, cutout_path, photo_type, display_order, created_at)
        SELECT id, shoe_id, file_path, NULL, 'main', 0, created_at
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

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createStickerTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shoe_id INTEGER NOT NULL UNIQUE,
        source_path TEXT NOT NULL,
        sticker_path TEXT NOT NULL,
        sticker_text TEXT,
        text_color INTEGER NOT NULL DEFAULT 4294928896,
        inner_border_color INTEGER NOT NULL DEFAULT 4294967295,
        outer_border_color INTEGER NOT NULL DEFAULT 4294928896,
        shadow_enabled INTEGER NOT NULL DEFAULT 1,
        preview_path TEXT,
        text_scale REAL NOT NULL DEFAULT 0.75,
        text_x REAL NOT NULL DEFAULT 0.5,
        text_y REAL NOT NULL DEFAULT 0.55,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (shoe_id) REFERENCES shoes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sticker_boards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        aspect_ratio REAL NOT NULL DEFAULT 0.8,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sticker_board_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        board_id INTEGER NOT NULL,
        sticker_id INTEGER NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        scale REAL NOT NULL DEFAULT 1.0,
        rotation REAL NOT NULL DEFAULT 0.0,
        z_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (board_id) REFERENCES sticker_boards(id) ON DELETE CASCADE,
        FOREIGN KEY (sticker_id) REFERENCES stickers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stickers_shoe_id ON stickers(shoe_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_board_items_board_id ON sticker_board_items(board_id)');
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
