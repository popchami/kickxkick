enum PhotoType {
  main,
  gallery,
  right,
  left,
  top,
  rear,
  sole,
  box,
  wear1,
  wear2,
  wear3,
}

class Photo {
  final int? id;
  final int shoeId;
  final PhotoType photoType;
  final String filePath;
  final String? cutoutPath;
  final int displayOrder;
  final DateTime createdAt;

  const Photo({
    this.id,
    required this.shoeId,
    required this.photoType,
    required this.filePath,
    this.cutoutPath,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Photo.create({
    required int shoeId,
    required PhotoType photoType,
    required String filePath,
    String? cutoutPath,
    int displayOrder = 0,
  }) {
    return Photo(
      shoeId: shoeId,
      photoType: photoType,
      filePath: filePath,
      cutoutPath: cutoutPath,
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
      cutoutPath: map['cutout_path'] as String?,
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
      'cutout_path': cutoutPath,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Photo copyWith({
    int? id,
    int? shoeId,
    PhotoType? photoType,
    String? filePath,
    String? cutoutPath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      shoeId: shoeId ?? this.shoeId,
      photoType: photoType ?? this.photoType,
      filePath: filePath ?? this.filePath,
      cutoutPath: cutoutPath ?? this.cutoutPath,
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
      case PhotoType.right:
        return 'right';
      case PhotoType.left:
        return 'left';
      case PhotoType.top:
        return 'top';
      case PhotoType.rear:
        return 'rear';
      case PhotoType.sole:
        return 'sole';
      case PhotoType.box:
        return 'box';
      case PhotoType.wear1:
        return 'wear1';
      case PhotoType.wear2:
        return 'wear2';
      case PhotoType.wear3:
        return 'wear3';
    }
  }

  static PhotoType fromDatabaseValue(String value) {
    switch (value) {
      case 'main':
        return PhotoType.main;
      case 'gallery':
        return PhotoType.gallery;
      case 'right':
        return PhotoType.right;
      case 'left':
        return PhotoType.left;
      case 'top':
        return PhotoType.top;
      case 'rear':
        return PhotoType.rear;
      case 'sole':
        return PhotoType.sole;
      case 'box':
        return PhotoType.box;
      case 'wear1':
        return PhotoType.wear1;
      case 'wear2':
        return PhotoType.wear2;
      case 'wear3':
        return PhotoType.wear3;
      default:
        throw ArgumentError('Unknown photo type: $value');
    }
  }
}
