import 'package:riverpod/riverpod.dart';

class CollectionFilter {
  final int? brandId;
  final bool favoritesOnly;

  const CollectionFilter({this.brandId, this.favoritesOnly = false});

  CollectionFilter copyWith({int? brandId, bool? favoritesOnly}) {
    return CollectionFilter(
      brandId: brandId,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

final collectionFilterProvider = StateProvider<CollectionFilter>((ref) {
  return const CollectionFilter();
});
