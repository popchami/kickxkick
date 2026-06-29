import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/sticker_asset.dart';

class StickerRepository {
  static const freeBoardItemLimit = 10;
  static const premiumBoardItemLimit = 30;

  Future<List<StickerAsset>> getStickers() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('stickers', orderBy: 'created_at DESC');
    final stickers = <StickerAsset>[];
    for (final row in rows) {
      var sticker = StickerAsset.fromMap(row);
      final preview = sticker.previewPath;
      if (preview == null ||
          !preview.endsWith('_v2.png') ||
          !await File(preview).exists()) {
        final generated = await _createPreview(
          sticker.stickerPath,
          sticker.shoeId,
        );
        await db.update(
          'stickers',
          {'preview_path': generated},
          where: 'id = ?',
          whereArgs: [sticker.id],
        );
        sticker = StickerAsset.fromMap({...row, 'preview_path': generated});
      }
      stickers.add(sticker);
    }
    return stickers;
  }

  Future<int> saveSticker({
    required int shoeId,
    required String sourcePath,
    required String stickerPath,
    String? stickerText,
    int textColor = 0xFFFF6A00,
    int innerBorderColor = 0xFFFFFFFF,
    int outerBorderColor = 0xFFFF6A00,
    bool shadowEnabled = true,
    double textScale = .75,
    double textX = .5,
    double textY = .55,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final previewPath = await _createPreview(stickerPath, shoeId);
    await db.rawInsert('''
      INSERT INTO stickers (
        shoe_id, source_path, sticker_path, sticker_text, text_color,
        inner_border_color, outer_border_color, shadow_enabled, preview_path,
        text_scale, text_x, text_y, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(shoe_id) DO UPDATE SET
        source_path = excluded.source_path,
        sticker_path = excluded.sticker_path,
        sticker_text = excluded.sticker_text,
        text_color = excluded.text_color,
        inner_border_color = excluded.inner_border_color,
        outer_border_color = excluded.outer_border_color,
        shadow_enabled = excluded.shadow_enabled,
        preview_path = excluded.preview_path,
        text_scale = excluded.text_scale,
        text_x = excluded.text_x,
        text_y = excluded.text_y,
        updated_at = excluded.updated_at
    ''', [
      shoeId,
      sourcePath,
      stickerPath,
      stickerText,
      textColor,
      innerBorderColor,
      outerBorderColor,
      shadowEnabled ? 1 : 0,
      previewPath,
      textScale,
      textX,
      textY,
      now,
      now,
    ]);
    final row = await db.query('stickers', columns: ['id'], where: 'shoe_id = ?', whereArgs: [shoeId], limit: 1);
    return row.first['id'] as int;
  }

  Future<String> _createPreview(String sourcePath, int shoeId) async {
    final decoded = img.decodeImage(await File(sourcePath).readAsBytes());
    if (decoded == null) return sourcePath;
    final trimmed = _trimTransparentPadding(decoded);
    const maxDimension = 640;
    final img.Image preview;
    if (trimmed.width <= maxDimension && trimmed.height <= maxDimension) {
      preview = trimmed;
    } else if (trimmed.width >= trimmed.height) {
      preview = img.copyResize(
        trimmed,
        width: maxDimension,
        interpolation: img.Interpolation.cubic,
      );
    } else {
      preview = img.copyResize(
        trimmed,
        height: maxDimension,
        interpolation: img.Interpolation.cubic,
      );
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'kickxkick', 'previews'));
    await directory.create(recursive: true);
    final output = p.join(directory.path, 'sticker_${shoeId}_v2.png');
    await File(output).writeAsBytes(
      Uint8List.fromList(img.encodePng(preview, level: 6)),
      flush: true,
    );
    return output;
  }

  img.Image _trimTransparentPadding(img.Image source) {
    var minX = source.width;
    var minY = source.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.getPixel(x, y).a <= 10) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < minX || maxY < minY) return source;
    final padding = (math.max(maxX - minX, maxY - minY) * .04)
        .round()
        .clamp(4, 40);
    final left = (minX - padding).clamp(0, source.width - 1);
    final top = (minY - padding).clamp(0, source.height - 1);
    final right = (maxX + padding).clamp(0, source.width - 1);
    final bottom = (maxY + padding).clamp(0, source.height - 1);
    return img.copyCrop(
      source,
      x: left,
      y: top,
      width: right - left + 1,
      height: bottom - top + 1,
    );
  }

  Future<int> ensureDefaultBoard() async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('sticker_boards', columns: ['id'], limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    final now = DateTime.now().toIso8601String();
    return db.insert('sticker_boards', {'name': 'MY BOARD', 'aspect_ratio': 0.8, 'created_at': now, 'updated_at': now});
  }

  Future<List<StickerBoardItem>> getBoardItems(int boardId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('sticker_board_items', where: 'board_id = ?', whereArgs: [boardId], orderBy: 'z_index');
    return rows.map(StickerBoardItem.fromMap).toList();
  }

  Future<void> addToBoard(int boardId, int stickerId) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('sticker_board_items', where: 'board_id = ? AND sticker_id = ?', whereArgs: [boardId, stickerId], limit: 1);
    if (existing.isNotEmpty) return;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sticker_board_items WHERE board_id = ?', [boardId])) ?? 0;
    final sx = 0.12 + (count % 3) * 0.25;
    final sy = 0.12 + (count ~/ 3) * 0.25;
    await db.insert('sticker_board_items', {
      'board_id': boardId, 'sticker_id': stickerId,
      'x': sx, 'y': sy, 'scale': 1.0, 'rotation': 0.0, 'z_index': count,
      'text_enabled': 0, 'text_content': '', 'text_color': '#FFFFFF',
      'text_size': 0.025, 'text_font': '',
      'text_x': (sx + 0.18).clamp(0.0, 0.9), 'text_y': (sy + 0.24).clamp(0.0, 0.9),
    });
  }

  Future<int> getBoardItemCount(int boardId) async {
    final db = await AppDatabase.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM sticker_board_items WHERE board_id = ?',
          [boardId],
        )) ??
        0;
  }

  Future<void> pasteToBoard(
    int boardId,
    int stickerId, {
    double? x,
    double? y,
  }) async {
    final db = await AppDatabase.instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM sticker_board_items WHERE board_id = ?',
          [boardId],
        )) ??
        0;
    final maxZ = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT MAX(z_index) FROM sticker_board_items WHERE board_id = ?',
          [boardId],
        )) ??
        -1;
    await db.insert('sticker_board_items', {
      'board_id': boardId,
      'sticker_id': stickerId,
      'x': x ?? 0.12 + (count % 3) * 0.08,
      'y': y ?? 0.12 + (count % 4) * 0.06,
      'scale': 1.0,
      'rotation': 0.0,
      'z_index': maxZ + 1,
    });
  }

  Future<void> bringToFront(StickerBoardItem item) async {
    final db = await AppDatabase.instance.database;
    final maxZ = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT MAX(z_index) FROM sticker_board_items WHERE board_id = ?',
          [item.boardId],
        )) ??
        item.zIndex;
    await db.update(
      'sticker_board_items',
      {'z_index': maxZ + 1},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateBoardItem(StickerBoardItem item) async {
    final db = await AppDatabase.instance.database;
    await db.update('sticker_board_items', {
      'x': item.x, 'y': item.y, 'scale': item.scale, 'rotation': item.rotation, 'z_index': item.zIndex,
      'text_enabled': item.textEnabled ? 1 : 0,
      'text_content': item.textContent,
      'text_color': item.textColor,
      'text_size': item.textSize,
      'text_font': item.textFont,
      'text_x': item.textX,
      'text_y': item.textY,
    }, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<StickerBoardItem> duplicateBoardItem(StickerBoardItem source) async {
    final db = await AppDatabase.instance.database;
    final nx = (source.x + .05).clamp(0.0, .78);
    final ny = (source.y + .05).clamp(0.0, .82);
    final id = await db.insert('sticker_board_items', {
      'board_id': source.boardId,
      'sticker_id': source.stickerId,
      'x': nx, 'y': ny,
      'scale': source.scale, 'rotation': source.rotation, 'z_index': source.zIndex + 1,
      'text_enabled': source.textEnabled ? 1 : 0,
      'text_content': source.textContent,
      'text_color': source.textColor,
      'text_size': source.textSize,
      'text_font': source.textFont,
      'text_x': (source.textX + .05).clamp(0.0, 0.9),
      'text_y': (source.textY + .05).clamp(0.0, 0.9),
    });
    return StickerBoardItem(
      id: id,
      boardId: source.boardId,
      stickerId: source.stickerId,
      x: nx, y: ny,
      scale: source.scale, rotation: source.rotation, zIndex: source.zIndex + 1,
      textEnabled: source.textEnabled,
      textContent: source.textContent,
      textColor: source.textColor,
      textSize: source.textSize,
      textFont: source.textFont,
      textX: (source.textX + .05).clamp(0.0, 0.9),
      textY: (source.textY + .05).clamp(0.0, 0.9),
    );
  }

  Future<void> deleteBoardItem(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('sticker_board_items', where: 'id = ?', whereArgs: [id]);
  }
}
