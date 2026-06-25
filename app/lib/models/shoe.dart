class Shoe {
  static const String statusNew = 'new';
  static const String statusWorn = 'worn';
  static const String statusParted = 'parted';

  final int? id;
  final int brandId;
  final String modelName;
  final String? displayTitle;
  final String? stickerText;
  final String status;
  final String? size;
  final String? color;
  final DateTime? purchaseDate;
  final int? purchasePrice;
  final String? purchaseStore;
  final String? memo;
  final bool isFavorite;
  final int? topOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shoe({
    this.id,
    required this.brandId,
    required this.modelName,
    this.displayTitle,
    this.stickerText,
    this.status = statusNew,
    this.size,
    this.color,
    this.purchaseDate,
    this.purchasePrice,
    this.purchaseStore,
    this.memo,
    this.isFavorite = false,
    this.topOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shoe.create({
    required int brandId,
    required String modelName,
    String? displayTitle,
    String? stickerText,
    String status = statusNew,
    String? size,
    String? color,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? purchaseStore,
    String? memo,
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    return Shoe(
      brandId: brandId,
      modelName: modelName,
      displayTitle: displayTitle,
      stickerText: stickerText,
      status: normalizeStatus(status),
      size: size,
      color: color,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      purchaseStore: purchaseStore,
      memo: memo,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Shoe.fromMap(Map<String, Object?> map) {
    return Shoe(
      id: map['id'] as int?,
      brandId: map['brand_id'] as int,
      modelName: map['model_name'] as String,
      displayTitle: map['display_title'] as String?,
      stickerText: map['sticker_text'] as String?,
      status: normalizeStatus(map['status'] as String?),
      size: map['size'] as String?,
      color: map['color'] as String?,
      purchaseDate: _parseDate(map['purchase_date'] as String?),
      purchasePrice: map['purchase_price'] as int?,
      purchaseStore: map['purchase_store'] as String?,
      memo: map['memo'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      topOrder: map['top_order'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'brand_id': brandId,
      'model_name': modelName,
      'display_title': displayTitle,
      'sticker_text': stickerText,
      'status': normalizeStatus(status),
      'size': size,
      'color': color,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'purchase_store': purchaseStore,
      'memo': memo,
      'is_favorite': isFavorite ? 1 : 0,
      'top_order': topOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shoe copyWith({
    int? id,
    int? brandId,
    String? modelName,
    String? displayTitle,
    String? stickerText,
    String? status,
    String? size,
    String? color,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? purchaseStore,
    String? memo,
    bool? isFavorite,
    int? topOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shoe(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      modelName: modelName ?? this.modelName,
      displayTitle: displayTitle ?? this.displayTitle,
      stickerText: stickerText ?? this.stickerText,
      status: normalizeStatus(status ?? this.status),
      size: size ?? this.size,
      color: color ?? this.color,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseStore: purchaseStore ?? this.purchaseStore,
      memo: memo ?? this.memo,
      isFavorite: isFavorite ?? this.isFavorite,
      topOrder: topOrder ?? this.topOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get archiveNumber {
    final id = this.id;
    if (id == null) return 'KXK-????';
    return 'KXK-${id.toString().padLeft(4, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case statusWorn:
        return '着用済み';
      case statusParted:
        return '手放した';
      case statusNew:
      default:
        return '新品';
    }
  }

  static String normalizeStatus(String? value) {
    switch (value) {
      case statusWorn:
      case statusParted:
      case statusNew:
        return value!;
      default:
        return statusNew;
    }
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
