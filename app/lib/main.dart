import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_fab.dart';

void main() {
  runApp(const ProviderScope(child: SoleMuseumApp()));
}

class SoleMuseumApp extends ConsumerWidget {
  const SoleMuseumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SoleMuseum',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SoleMuseumHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SoleMuseumHome extends ConsumerWidget {
  const SoleMuseumHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavigationIndexProvider);

    final screens = [
      const HomeScreen(),
      const CollectionScreen(),
      const SettingsScreen(),
    ];

    final showFab = currentIndex == 0 || currentIndex == 1;

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(bottomNavigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
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
      floatingActionButton: showFab ? const AppFab() : null,
    );
  }
}
