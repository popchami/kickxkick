import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class BackupService {
  static const String formatName = 'solemuseum-backup';
  static const int formatVersion = 1;

  Future<File> createBackupFile() async {
    final db = await AppDatabase.instance.database;
    final brands = await db.query('brands', orderBy: 'sort_order ASC');
    final shoes = await db.query('shoes', orderBy: 'created_at ASC');
    final wearLogs = await db.query(
      'wear_logs',
      orderBy: 'worn_date ASC, created_at ASC',
    );
    final generatedAt = DateTime.now();

    final payload = {
      'format': formatName,
      'version': formatVersion,
      'generated_at': generatedAt.toIso8601String(),
      'photos_included': false,
      'data': {
        'brands': brands,
        'shoes': shoes,
        'wear_logs': wearLogs,
      },
    };

    final appDirectory = await getApplicationDocumentsDirectory();
    final backupDirectory = Directory(
      path.join(appDirectory.path, 'solemuseum', 'backups'),
    );
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    final stamp = generatedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      path.join(backupDirectory.path, 'solemuseum_backup_$stamp.json'),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  Future<void> restoreBackupFile(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('バックアップ形式が正しくありません');
    }
    if (decoded['format'] != formatName ||
        decoded['version'] != formatVersion) {
      throw const FormatException('対応していないバックアップです');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('バックアップデータがありません');
    }

    final brands = _readRows(data, 'brands');
    final shoes = _readRows(data, 'shoes');
    final wearLogs = _readRows(data, 'wear_logs');

    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete('wear_logs');
      await txn.delete('photos');
      await txn.delete('shoes');
      await txn.delete('brands');

      for (final row in brands) {
        await txn.insert('brands', _brandRow(row));
      }
      for (final row in shoes) {
        await txn.insert('shoes', _shoeRow(row));
      }
      for (final row in wearLogs) {
        await txn.insert('wear_logs', _wearLogRow(row));
      }
    });
  }

  List<Map<String, dynamic>> _readRows(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is! List) {
      throw FormatException('$key がありません');
    }
    return value.map((row) {
      if (row is! Map) {
        throw FormatException('$key の内容が正しくありません');
      }
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Map<String, Object?> _brandRow(Map<String, dynamic> row) {
    return {
      'id': _requiredInt(row, 'id'),
      'name': _requiredString(row, 'name'),
      'sort_order': _requiredInt(row, 'sort_order'),
    };
  }

  Map<String, Object?> _shoeRow(Map<String, dynamic> row) {
    return {
      'id': _requiredInt(row, 'id'),
      'brand_id': _requiredInt(row, 'brand_id'),
      'model_name': _requiredString(row, 'model_name'),
      'size': row['size'] as String?,
      'color': row['color'] as String?,
      'purchase_date': row['purchase_date'] as String?,
      'purchase_price': row['purchase_price'] as int?,
      'purchase_store': row['purchase_store'] as String?,
      'memo': row['memo'] as String?,
      'is_favorite': _requiredInt(row, 'is_favorite'),
      'top_order': row['top_order'] as int?,
      'created_at': _requiredString(row, 'created_at'),
      'updated_at': _requiredString(row, 'updated_at'),
    };
  }

  Map<String, Object?> _wearLogRow(Map<String, dynamic> row) {
    return {
      'id': _requiredInt(row, 'id'),
      'shoe_id': _requiredInt(row, 'shoe_id'),
      'worn_date': _requiredString(row, 'worn_date'),
      'memo': row['memo'] as String?,
      'created_at': _requiredString(row, 'created_at'),
    };
  }

  int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! int) {
      throw FormatException('$key が正しくありません');
    }
    return value;
  }

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key が正しくありません');
    }
    return value;
  }
}
