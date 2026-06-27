import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/sticker_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shoe_form_screen.dart';

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
      body: screens[currentIndex],
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
            label: '＋',
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
