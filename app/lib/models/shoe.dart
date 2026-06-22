enum ShoeStatus {
  owned,
  wishlist,
  sold;

  String get databaseValue => name;

  String get label {
    switch (this) {
      case ShoeStatus.owned:
        return '所有中';
      case ShoeStatus.wishlist:
        return 'ほしいリスト';
      case ShoeStatus.sold:
        return '売却済み';
    }
  }

  static ShoeStatus fromDatabase(String? value) {
    return ShoeStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ShoeStatus.owned,
    );
  }
}

class Shoe {
  final int? id;
  final int brandId;
  final String modelName;
  final String? size;
  final String? color;
  final DateTime? purchaseDate;
  final int? purchasePrice;
  final String? purchaseStore;
  final String? memo;
  final bool isFavorite;
  final int? topOrder;
  final ShoeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shoe({
    this.id,
    required this.brandId,
    required this.modelName,
    this.size,
    this.color,
    this.purchaseDate,
    this.purchasePrice,
    this.purchaseStore,
    this.memo,
    this.isFavorite = false,
    this.topOrder,
    this.status = ShoeStatus.owned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shoe.create({
    required int brandId,
    required String modelName,
    String? size,
    String? color,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? purchaseStore,
    String? memo,
    bool isFavorite = false,
    ShoeStatus status = ShoeStatus.owned,
  }) {
    final now = DateTime.now();
    return Shoe(
      brandId: brandId,
      modelName: modelName,
      size: size,
      color: color,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      purchaseStore: purchaseStore,
      memo: memo,
      isFavorite: isFavorite,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Shoe.fromMap(Map<String, Object?> map) {
    return Shoe(
      id: map['id'] as int?,
      brandId: map['brand_id'] as int,
      modelName: map['model_name'] as String,
      size: map['size'] as String?,
      color: map['color'] as String?,
      purchaseDate: _parseDate(map['purchase_date'] as String?),
      purchasePrice: map['purchase_price'] as int?,
      purchaseStore: map['purchase_store'] as String?,
      memo: map['memo'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      topOrder: map['top_order'] as int?,
      status: ShoeStatus.fromDatabase(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'brand_id': brandId,
      'model_name': modelName,
      'size': size,
      'color': color,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'purchase_store': purchaseStore,
      'memo': memo,
      'is_favorite': isFavorite ? 1 : 0,
      'top_order': topOrder,
      'status': status.databaseValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shoe copyWith({
    int? id,
    int? brandId,
    String? modelName,
    String? size,
    String? color,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? purchaseStore,
    String? memo,
    bool? isFavorite,
    int? topOrder,
    ShoeStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shoe(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      modelName: modelName ?? this.modelName,
      size: size ?? this.size,
      color: color ?? this.color,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseStore: purchaseStore ?? this.purchaseStore,
      memo: memo ?? this.memo,
      isFavorite: isFavorite ?? this.isFavorite,
      topOrder: topOrder ?? this.topOrder,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get archiveNumber {
    final id = this.id;
    if (id == null) return 'SM-????';
    return 'SM-${id.toString().padLeft(4, '0')}';
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
