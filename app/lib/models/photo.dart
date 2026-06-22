enum PhotoType {
  main,
  gallery,
  box,
}

class Photo {
  final int? id;
  final int shoeId;
  final PhotoType photoType;
  final String filePath;
  final int displayOrder;
  final DateTime createdAt;

  const Photo({
    this.id,
    required this.shoeId,
    required this.photoType,
    required this.filePath,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Photo.create({
    required int shoeId,
    required PhotoType photoType,
    required String filePath,
    int displayOrder = 0,
  }) {
    return Photo(
      shoeId: shoeId,
      photoType: photoType,
      filePath: filePath,
      displayOrder: displayOrder,
      createdAt: DateTime.now(),
    );
  }

  factory Photo.fromMap(Map<String, Object?> map) {
    return Photo(
      id: map['id'] as int?,
      shoeId: map['shoe_id'] as int,
      photoType: PhotoTypeX.fromDatabaseValue(map['photo_type'] as String),
      filePath: map['file_path'] as String,
      displayOrder: map['display_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'shoe_id': shoeId,
      'photo_type': photoType.databaseValue,
      'file_path': filePath,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Photo copyWith({
    int? id,
    int? shoeId,
    PhotoType? photoType,
    String? filePath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      shoeId: shoeId ?? this.shoeId,
      photoType: photoType ?? this.photoType,
      filePath: filePath ?? this.filePath,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension PhotoTypeX on PhotoType {
  String get databaseValue {
    switch (this) {
      case PhotoType.main:
        return 'main';
      case PhotoType.gallery:
        return 'gallery';
      case PhotoType.box:
        return 'box';
    }
  }

  static PhotoType fromDatabaseValue(String value) {
    switch (value) {
      case 'main':
        return PhotoType.main;
      case 'gallery':
        return PhotoType.gallery;
      case 'box':
        return PhotoType.box;
      default:
        throw ArgumentError('Unknown photo type: $value');
    }
  }
}
