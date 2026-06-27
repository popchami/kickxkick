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

    } catch (_) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('保存できませんでした'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
          ),
        );
      }
    }
  }

  Future<void> _editMemo(
    BuildContext context,
    WidgetRef ref,
    WearLog wearLog,
  ) async {
    final controller = TextEditingController(text: wearLog.memo ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_formatDate(wearLog.wornDate)}のメモ'),
        content: TextField(controller: controller, maxLines: 3, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || wearLog.id == null) return;
    await ref.read(wearLogRepositoryProvider).updateMemo(
      wearLog.id!,
      value.isEmpty ? null : value,
    );
    ref.invalidate(wearLogsByShoeIdProvider(shoeId));
    ref.invalidate(recentWearLogsProvider);
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
              children: [
                _WearCalendar(wearLogs: wearLogs),
                const SizedBox(height: 12),
                ...wearLogs
                  .map(
                    (wearLog) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(_formatDate(wearLog.wornDate)),
                        subtitle:
                            wearLog.memo == null ? null : Text(wearLog.memo!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'メモを編集',
                              onPressed: () => _editMemo(context, ref, wearLog),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: '着用記録を削除',
                              onPressed: () => _deleteWearLog(context, ref, wearLog),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
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

class _WearCalendar extends StatefulWidget {
  const _WearCalendar({required this.wearLogs});
  final List<WearLog> wearLogs;

  @override
  State<_WearCalendar> createState() => _WearCalendarState();
}

class _WearCalendarState extends State<_WearCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday % 7;
    final wornDays = widget.wearLogs
        .where((log) => log.wornDate.year == _month.year && log.wornDate.month == _month.month)
        .map((log) => log.wornDate.day)
        .toSet();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left)),
                Expanded(child: Text('${_month.year}年 ${_month.month}月', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right)),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: offset + days,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = index - offset + 1;
                final worn = wornDays.contains(day);
                return Center(
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: worn ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                    child: Text('$day'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
