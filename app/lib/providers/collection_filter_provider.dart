import 'package:riverpod/riverpod.dart';

class CollectionFilter {
  final int? brandId;
  final String? status;

  const CollectionFilter({
    this.brandId,
    this.status,
  });

  CollectionFilter copyWith({
    int? brandId,
    String? status,
  }) {
    return CollectionFilter(
      brandId: brandId,
      status: status,
    );
  }
}

final collectionFilterProvider = StateProvider<CollectionFilter>((ref) {
  return const CollectionFilter();
});
