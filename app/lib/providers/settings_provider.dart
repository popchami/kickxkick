import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/background_theme.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// アプリ全体(HOME・設定画面)の背景テーマ。Board/棚ごとの設定とは別軸。
final appBackgroundThemeProvider =
    AsyncNotifierProvider<AppBackgroundThemeNotifier, BackgroundTheme>(
  AppBackgroundThemeNotifier.new,
);

class AppBackgroundThemeNotifier extends AsyncNotifier<BackgroundTheme> {
  static const _key = 'app_background_theme';

  @override
  Future<BackgroundTheme> build() async {
    final raw = await ref.read(settingsRepositoryProvider).getValue(_key);
    return BackgroundTheme.fromKey(raw);
  }

  Future<void> setTheme(BackgroundTheme theme) async {
    state = AsyncData(theme);
    await ref.read(settingsRepositoryProvider).setValue(_key, theme.key);
  }
}

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
