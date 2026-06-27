import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../features/search/screens/search_demo_screen.dart';
import '../providers/backup_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/wear_log_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      final file = await ref.read(backupServiceProvider).createBackupFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'KickxKick Backup',
          text: 'KickxKick collection backup.',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バックアップの作成に失敗しました')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final filePath = result?.files.single.path;
    if (filePath == null || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップを復元しますか？'),
        content: const Text(
          '現在のコレクション、着用履歴、TOP 5をバックアップ内容で置き換えます。\n\n'
          '写真ファイルはバックアップに含まれないため、写真の登録情報は削除されます。'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('復元する'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(backupServiceProvider).restoreBackupFile(File(filePath));
      ref.invalidate(brandsProvider);
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider);
      ref.invalidate(photosByShoeIdProvider);
      ref.invalidate(mainPhotoProvider);
      ref.invalidate(wearLogsByShoeIdProvider);
      ref.invalidate(recentWearLogsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バックアップを復元しました')),
        );
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バックアップの復元に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const _SectionTitle(title: '表示'),
          ListTile(
            title: const Text('テーマ'),
            subtitle: Text(
              themeMode == ThemeMode.light
                  ? 'ライト'
                  : themeMode == ThemeMode.dark
                      ? 'ダーク'
                      : 'システム設定',
            ),
            trailing: PopupMenuButton<ThemeMode>(
              initialValue: themeMode,
              onSelected: (value) {
                ref.read(themeModeProvider.notifier).state = value;
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text('ライト'),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text('ダーク'),
                ),
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('システム設定'),
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionTitle(title: '開発'),
          ListTile(
            leading: const Icon(Icons.search_outlined),
            title: const Text('検索デモ'),
            subtitle: const Text('ブランド・モデル候補の動作を確認します'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchDemoScreen()),
              );
            },
          ),
          const Divider(),
          const _SectionTitle(title: 'バックアップ'),
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('バックアップを作成'),
            subtitle: const Text('コレクションデータを保存・共有します（写真は対象外）'),
            onTap: () => _createBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('バックアップから復元'),
            subtitle: const Text('保存したバックアップからコレクションを復元します'),
            onTap: () => _restoreBackup(context, ref),
          ),
          const Divider(),
          const _SectionTitle(title: 'アプリ情報'),
          const ListTile(
            title: Text('KickxKick'),
            subtitle: Text('v1.0.0'),
          ),
          const ListTile(
            title: Text('Collect. Create. Exhibit.'),
            subtitle: Text('Sneaker Sticker Collection App'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
