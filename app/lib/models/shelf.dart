import 'background_theme.dart';

class Shelf {
  const Shelf({
    required this.id,
    required this.name,
    required this.backgroundTheme,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final BackgroundTheme backgroundTheme;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Shelf.fromMap(Map<String, Object?> map) => Shelf(
        id: map['id'] as int,
        name: map['name'] as String,
        backgroundTheme:
            BackgroundTheme.fromKey(map['background_theme'] as String?),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class ShelfItem {
  const ShelfItem({
    required this.id,
    required this.shelfId,
    required this.shoeId,
    required this.slotIndex,
  });

  final int id;
  final int shelfId;
  final int shoeId;
  final int slotIndex;

  factory ShelfItem.fromMap(Map<String, Object?> map) => ShelfItem(
        id: map['id'] as int,
        shelfId: map['shelf_id'] as int,
        shoeId: map['shoe_id'] as int,
        slotIndex: map['slot_index'] as int,
      );
}
