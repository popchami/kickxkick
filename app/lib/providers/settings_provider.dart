import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final collectionColumnsProvider =
    AsyncNotifierProvider<CollectionColumnsNotifier, int>(
  CollectionColumnsNotifier.new,
);

class CollectionColumnsNotifier extends AsyncNotifier<int> {
  static const _key = 'collection_columns';

  @override
  Future<int> build() async {
    final raw = await ref.read(settingsRepositoryProvider).getValue(_key);
    return (int.tryParse(raw ?? '') ?? 2).clamp(2, 5);
  }

  Future<void> setColumns(int columns) async {
    final value = columns.clamp(2, 5);
    state = AsyncData(value);
    await ref.read(settingsRepositoryProvider).setValue(_key, '$value');
  }
}
