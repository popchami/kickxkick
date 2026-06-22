import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shoe.dart';
import '../models/wear_log.dart';
import '../providers/brand_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';
import '../screens/shoe_form_screen.dart';

enum _AppFabAction { addShoe, recordWear }

class AppFab extends ConsumerWidget {
  const AppFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () async {
        final action = await showModalBottomSheet<_AppFabAction>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('靴を登録'),
                      onTap: () {
                        Navigator.of(sheetContext).pop(_AppFabAction.addShoe);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: const Text('今日履いた'),
                      onTap: () {
                        Navigator.of(sheetContext)
                            .pop(_AppFabAction.recordWear);
                      },
                    ),
                    const ListTile(
                      leading: Icon(Icons.ios_share_outlined),
                      title: Text('コレクション共有'),
                      subtitle: Text('今後のアップデートで追加予定'),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (!context.mounted || action == null) {
          return;
        }

        if (action == _AppFabAction.addShoe) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
          );
          return;
        }

        final shoe = await showModalBottomSheet<Shoe>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _TodayWornPicker(),
        );
        if (shoe != null && context.mounted) {
          await _TodayWornPicker.recordWearForShoe(context, ref, shoe);
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class _TodayWornPicker extends ConsumerWidget {
  const _TodayWornPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '今日履いた靴を選んでください',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: shoesAsync.when(
              data: (shoes) {
                if (shoes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'スニーカーが登録されていません',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return brandsAsync.when(
                  data: (brands) {
                    final brandNames = {
                      for (final b in brands)
                        if (b.id != null) b.id!: b.name,
                    };
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: shoes.length,
                      itemBuilder: (_, index) {
                        final shoe = shoes[index];
                        return ListTile(
                          title: Text(shoe.modelName),
                          subtitle: Text(brandNames[shoe.brandId] ?? ''),
                          trailing: Text(
                            shoe.archiveNumber,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          onTap: () => Navigator.of(context).pop(shoe),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('読み込みに失敗しました'),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(32),
                child: Text('読み込みに失敗しました'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> recordWearForShoe(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final wearLogRepository = ref.read(wearLogRepositoryProvider);
    var memoText = '';

    final memo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${shoe.modelName}\n今日の着用記録'),
        content: TextField(
          onChanged: (value) => memoText = value,
          decoration: const InputDecoration(
            labelText: 'メモ（任意）',
            hintText: '行き先や天気など',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(memoText.trim()),
            child: const Text('記録'),
          ),
        ],
      ),
    );

    if (memo == null || !context.mounted) {
      return;
    }

    try {
      final inserted = await wearLogRepository.insertWearLog(
        WearLog.create(
          shoeId: shoe.id!,
          wornDate: DateTime.now(),
          memo: memo.isEmpty ? null : memo,
        ),
      );
      ref.invalidate(wearLogsByShoeIdProvider(shoe.id!));
      ref.invalidate(recentWearLogsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            inserted ? '${shoe.modelName}の着用を記録しました' : '今日はすでに記録済みです',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('着用記録の保存に失敗しました')),
      );
    }
  }
}
