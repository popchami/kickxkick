import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wear_log.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';

class WearHistorySection extends ConsumerWidget {
  final int shoeId;

  const WearHistorySection({super.key, required this.shoeId});

  Future<void> _recordToday(BuildContext context, WidgetRef ref) async {
    var memoText = '';
    final memo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('今日履いた'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(memoText.trim()),
            child: const Text('記録'),
          ),
        ],
      ),
    );

    if (memo == null) {
      return;
    }

    try {
      final inserted = await ref.read(wearLogRepositoryProvider).insertWearLog(
            WearLog.create(
              shoeId: shoeId,
              wornDate: DateTime.now(),
              memo: memo.isEmpty ? null : memo,
            ),
          );
      if (inserted) {
        await ref.read(shoeRepositoryProvider).markWornIfNew(shoeId);
      }
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider(shoeId));
      ref.invalidate(wearLogsByShoeIdProvider(shoeId));
      ref.invalidate(recentWearLogsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inserted ? '今日の着用を記録しました' : '今日はすでに記録済みです'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('着用記録の保存に失敗しました')),
        );
      }
    }
  }

  Future<void> _deleteWearLog(
    BuildContext context,
    WidgetRef ref,
    WearLog wearLog,
  ) async {
    final id = wearLog.id;
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('着用記録を削除しますか？'),
        content: Text('${_formatDate(wearLog.wornDate)}の記録を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(wearLogRepositoryProvider).deleteWearLog(id);
    ref.invalidate(wearLogsByShoeIdProvider(shoeId));
    ref.invalidate(recentWearLogsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearLogsAsync = ref.watch(wearLogsByShoeIdProvider(shoeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _recordToday(context, ref),
          icon: const Icon(Icons.directions_walk),
          label: const Text('今日履いた'),
        ),
        const SizedBox(height: 20),
        Text('着用履歴', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        wearLogsAsync.when(
          data: (wearLogs) {
            if (wearLogs.isEmpty) {
              return Text(
                'まだ着用記録がありません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              );
            }

            return Column(
              children: wearLogs
                  .map(
                    (wearLog) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(_formatDate(wearLog.wornDate)),
                        subtitle:
                            wearLog.memo == null ? null : Text(wearLog.memo!),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '着用記録を削除',
                          onPressed: () =>
                              _deleteWearLog(context, ref, wearLog),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('着用履歴を読み込めませんでした'),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
