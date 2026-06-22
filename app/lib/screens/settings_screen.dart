import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Display',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(
              themeMode == ThemeMode.light
                  ? 'Light'
                  : themeMode == ThemeMode.dark
                      ? 'Dark'
                      : 'System',
            ),
            trailing: PopupMenuButton<ThemeMode>(
              initialValue: themeMode,
              onSelected: (ThemeMode value) {
                ref.read(themeModeProvider.notifier).state = value;
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const ListTile(
            title: Text('SoleMuseum'),
            subtitle: Text('v1.0.0'),
          ),
          const ListTile(
            title: Text('Collect. Preserve. Showcase.'),
            subtitle: Text('Digital Sneaker Collection Museum'),
          ),
        ],
      ),
    );
  }
}
