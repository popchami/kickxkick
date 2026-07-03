class StickerBoard {
  const StickerBoard({
    required this.id,
    required this.name,
    required this.aspectRatio,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final double aspectRatio;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StickerBoard.fromMap(Map<String, Object?> map) => StickerBoard(
        id: map['id'] as int,
        name: map['name'] as String,
        aspectRatio: (map['aspect_ratio'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
