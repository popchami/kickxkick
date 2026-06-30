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
  final String? cutoutMaskPath;
  final double cutoutThreshold;
  final String? cutoutEngine;
  final double cutoutSmoothing;
  final double cutoutAntialiasing;
  final int displayOrder;
  final DateTime createdAt;

  const Photo({
    this.id,
    required this.shoeId,
    required this.photoType,
    required this.filePath,
    this.cutoutPath,
    this.cutoutMaskPath,
    this.cutoutThreshold = 90,
    this.cutoutEngine,
    this.cutoutSmoothing = 50,
    this.cutoutAntialiasing = 50,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Photo.create({
    required int shoeId,
    required PhotoType photoType,
    required String filePath,
    String? cutoutPath,
    String? cutoutMaskPath,
    double cutoutThreshold = 90,
    String? cutoutEngine,
    double cutoutSmoothing = 50,
    double cutoutAntialiasing = 50,
    int displayOrder = 0,
  }) {
    return Photo(
      shoeId: shoeId,
      photoType: photoType,
      filePath: filePath,
      cutoutPath: cutoutPath,
      cutoutMaskPath: cutoutMaskPath,
      cutoutThreshold: cutoutThreshold,
      cutoutEngine: cutoutEngine,
      cutoutSmoothing: cutoutSmoothing,
      cutoutAntialiasing: cutoutAntialiasing,
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
      cutoutMaskPath: map['cutout_mask_path'] as String?,
      cutoutThreshold: (map['cutout_threshold'] as num?)?.toDouble() ?? 90,
      cutoutEngine: map['cutout_engine'] as String?,
      cutoutSmoothing: (map['cutout_smoothing'] as num?)?.toDouble() ?? 50,
      cutoutAntialiasing: (map['cutout_antialiasing'] as num?)?.toDouble() ?? 50,
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
      'cutout_mask_path': cutoutMaskPath,
      'cutout_threshold': cutoutThreshold,
      'cutout_engine': cutoutEngine,
      'cutout_smoothing': cutoutSmoothing,
      'cutout_antialiasing': cutoutAntialiasing,
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
    String? cutoutMaskPath,
    double? cutoutThreshold,
    String? cutoutEngine,
    double? cutoutSmoothing,
    double? cutoutAntialiasing,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      shoeId: shoeId ?? this.shoeId,
      photoType: photoType ?? this.photoType,
      filePath: filePath ?? this.filePath,
      cutoutPath: cutoutPath ?? this.cutoutPath,
      cutoutMaskPath: cutoutMaskPath ?? this.cutoutMaskPath,
      cutoutThreshold: cutoutThreshold ?? this.cutoutThreshold,
      cutoutEngine: cutoutEngine ?? this.cutoutEngine,
      cutoutSmoothing: cutoutSmoothing ?? this.cutoutSmoothing,
      cutoutAntialiasing: cutoutAntialiasing ?? this.cutoutAntialiasing,
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
