import 'package:riverpod/riverpod.dart';

class CollectionFilter {
  final int? brandId;
  final String? status;
  final String? color;

  const CollectionFilter({
    this.brandId,
    this.status,
    this.color,
  });

  CollectionFilter copyWith({
    int? brandId,
    String? status,
    String? color,
  }) {
    return CollectionFilter(
      brandId: brandId,
      status: status,
      color: color,
    );
  }
}

final collectionFilterProvider = StateProvider<CollectionFilter>((ref) {
  return const CollectionFilter();
});
