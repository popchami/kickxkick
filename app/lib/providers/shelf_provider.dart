import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shelf.dart';
import '../repositories/shelf_repository.dart';

final shelfRepositoryProvider = Provider((ref) => ShelfRepository());

final defaultShelfIdProvider = FutureProvider<int>((ref) {
  return ref.watch(shelfRepositoryProvider).ensureDefaultShelf();
});

final shelfItemsProvider =
    FutureProvider.family<List<ShelfItem>, int>((ref, shelfId) {
  return ref.watch(shelfRepositoryProvider).getShelfItems(shelfId);
});
