class StickerAsset {
  const StickerAsset({
    required this.id,
    required this.shoeId,
    required this.sourcePath,
    required this.stickerPath,
    this.stickerText,
    this.textColor = 0xFFFF6A00,
    this.innerBorderColor = 0xFFFFFFFF,
    this.outerBorderColor = 0xFFFF6A00,
    this.shadowEnabled = true,
    this.previewPath,
    this.textScale = .75,
    this.textX = .5,
    this.textY = .55,
  });

  final int id;
  final int shoeId;
  final String sourcePath;
  final String stickerPath;
  final String? stickerText;
  final int textColor;
  final int innerBorderColor;
  final int outerBorderColor;
  final bool shadowEnabled;
  final String? previewPath;
  final double textScale;
  final double textX;
  final double textY;

  String get displayPath => previewPath ?? stickerPath;

  factory StickerAsset.fromMap(Map<String, Object?> map) => StickerAsset(
        id: map['id'] as int,
        shoeId: map['shoe_id'] as int,
        sourcePath: map['source_path'] as String,
        stickerPath: map['sticker_path'] as String,
        stickerText: map['sticker_text'] as String?,
        textColor: (map['text_color'] as num?)?.toInt() ?? 0xFFFF6A00,
        innerBorderColor:
            (map['inner_border_color'] as num?)?.toInt() ?? 0xFFFFFFFF,
        outerBorderColor:
            (map['outer_border_color'] as num?)?.toInt() ?? 0xFFFF6A00,
        shadowEnabled: ((map['shadow_enabled'] as num?)?.toInt() ?? 1) == 1,
        previewPath: map['preview_path'] as String?,
        textScale: (map['text_scale'] as num?)?.toDouble() ?? .75,
        textX: (map['text_x'] as num?)?.toDouble() ?? .5,
        textY: (map['text_y'] as num?)?.toDouble() ?? .55,
      );
}

class StickerBoardItem {
  const StickerBoardItem({
    required this.id,
    required this.boardId,
    required this.stickerId,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.zIndex,
  });

  final int id;
  final int boardId;
  final int stickerId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;

  factory StickerBoardItem.fromMap(Map<String, Object?> map) => StickerBoardItem(
        id: map['id'] as int,
        boardId: map['board_id'] as int,
        stickerId: map['sticker_id'] as int,
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        scale: (map['scale'] as num).toDouble(),
        rotation: (map['rotation'] as num).toDouble(),
        zIndex: map['z_index'] as int,
      );
}
