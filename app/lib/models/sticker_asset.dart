class StickerAsset {
  const StickerAsset({
    required this.id,
    required this.shoeId,
    required this.sourcePath,
    required this.stickerPath,
  });

  final int id;
  final int shoeId;
  final String sourcePath;
  final String stickerPath;

  factory StickerAsset.fromMap(Map<String, Object?> map) => StickerAsset(
        id: map['id'] as int,
        shoeId: map['shoe_id'] as int,
        sourcePath: map['source_path'] as String,
        stickerPath: map['sticker_path'] as String,
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
