import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/sticker_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shoe_form_screen.dart';
import 'widgets/themed_background.dart';

void main() {
  runApp(const ProviderScope(child: KickxKickApp()));
}

class KickxKickApp extends ConsumerWidget {
  const KickxKickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kick×Kick',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const KickxKickHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KickxKickHome extends ConsumerWidget {
  const KickxKickHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavigationIndexProvider);

    final screens = [
      const HomeScreen(),
      const StickerScreen(),
      const SizedBox.shrink(),
      const CollectionScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // HOME・設定画面にだけ共通の背景を敷く。Sticker Board・棚は
          // 将来個別にテーマ(背景)を選べるようにする予定のため対象外。
          if (currentIndex == 0 || currentIndex == 4) const _AppBackground(),
          screens[currentIndex],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
            );
            return;
          }
          ref.read(bottomNavigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Sticker',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, color: Colors.orange),
            selectedIcon: Icon(Icons.add_circle, color: Colors.orange),
            label: '追加',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// HOME・設定画面が共通で透かして見せる背景レイヤー。読み込み中に画面全体を
/// スピナーで止めないよう、ThemedBackgroundと同じフォールバック色を
/// 即座に表示し、テーマ読み込み後に画像へ切り替える。
class _AppBackground extends ConsumerWidget {
  const _AppBackground();

  static const _fallbackColor = Color(0xFFF3E7D3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundTheme = ref.watch(appBackgroundThemeProvider).value;
    if (backgroundTheme == null) {
      return const ColoredBox(color: _fallbackColor);
    }
    return ThemedBackground(
      theme: backgroundTheme,
      child: const SizedBox.shrink(),
    );
  }
}
