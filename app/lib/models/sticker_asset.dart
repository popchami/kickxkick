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
    this.cropOffsetXFrac = 0,
    this.cropOffsetYFrac = 0,
    this.cropWidthFrac = 1,
    this.cropHeightFrac = 1,
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
  final double cropOffsetXFrac;
  final double cropOffsetYFrac;
  final double cropWidthFrac;
  final double cropHeightFrac;

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
        cropOffsetXFrac: (map['crop_offset_x_frac'] as num?)?.toDouble() ?? 0,
        cropOffsetYFrac: (map['crop_offset_y_frac'] as num?)?.toDouble() ?? 0,
        cropWidthFrac: (map['crop_width_frac'] as num?)?.toDouble() ?? 1,
        cropHeightFrac: (map['crop_height_frac'] as num?)?.toDouble() ?? 1,
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
    this.textEnabled = false,
    this.textContent = '',
    this.textColor = '#FFFFFF',
    this.textSize = 0.025,
    this.textFont = '',
    this.textX = 0.7,
    this.textY = 0.75,
  });

  final int id;
  final int boardId;
  final int stickerId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
  final bool textEnabled;
  final String textContent;
  final String textColor;
  final double textSize;
  final String textFont;
  final double textX;
  final double textY;

  factory StickerBoardItem.fromMap(Map<String, Object?> map) => StickerBoardItem(
        id: map['id'] as int,
        boardId: map['board_id'] as int,
        stickerId: map['sticker_id'] as int,
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        scale: (map['scale'] as num).toDouble(),
        rotation: (map['rotation'] as num).toDouble(),
        zIndex: map['z_index'] as int,
        textEnabled: (map['text_enabled'] as int? ?? 0) == 1,
        textContent: map['text_content'] as String? ?? '',
        textColor: map['text_color'] as String? ?? '#FFFFFF',
        textSize: (map['text_size'] as num? ?? 0.025).toDouble(),
        textFont: map['text_font'] as String? ?? '',
        textX: (map['text_x'] as num? ?? 0.7).toDouble(),
        textY: (map['text_y'] as num? ?? 0.75).toDouble(),
      );

  StickerBoardItem copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? textEnabled,
    String? textContent,
    String? textColor,
    double? textSize,
    String? textFont,
    double? textX,
    double? textY,
  }) =>
      StickerBoardItem(
        id: id,
        boardId: boardId,
        stickerId: stickerId,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        textEnabled: textEnabled ?? this.textEnabled,
        textContent: textContent ?? this.textContent,
        textColor: textColor ?? this.textColor,
        textSize: textSize ?? this.textSize,
        textFont: textFont ?? this.textFont,
        textX: textX ?? this.textX,
        textY: textY ?? this.textY,
      );
}
