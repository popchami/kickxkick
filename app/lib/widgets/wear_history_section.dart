import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wear_log.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';

class WearHistorySection extends ConsumerWidget {
  final int shoeId;

  const WearHistorySection({super.key, required this.shoeId});

  Future<void> _recordDate(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    var memoText = '';
    final memo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_formatDate(date)}に履いた'),
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
              wornDate: date,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (value == null || wearLog.id == null) return;
    try {
      await ref.read(wearLogRepositoryProvider).updateMemo(
        wearLog.id!,
        value.isEmpty ? null : value,
      );
      ref.invalidate(wearLogsByShoeIdProvider(shoeId));
      ref.invalidate(recentWearLogsProvider);
    } catch (error, stackTrace) {
      debugPrint('Wear memo update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを保存できませんでした')),
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

  Future<void> _manageWearLog(
    BuildContext context,
    WidgetRef ref,
    WearLog wearLog,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_formatDate(wearLog.wornDate)),
              subtitle: Text(wearLog.memo?.isNotEmpty == true
                  ? wearLog.memo!
                  : 'メモはありません'),
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('メモを編集'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('着用記録を削除'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _editMemo(context, ref, wearLog);
    } else if (action == 'delete') {
      await _deleteWearLog(context, ref, wearLog);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearLogsAsync = ref.watch(wearLogsByShoeIdProvider(shoeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('着用履歴', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        wearLogsAsync.when(
          data: (wearLogs) => _WearCalendar(
            wearLogs: wearLogs,
            onRecordDate: (date) => _recordDate(context, ref, date),
            onTapWearLog: (wearLog) => _manageWearLog(context, ref, wearLog),
          ),
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
  const _WearCalendar({
    required this.wearLogs,
    required this.onRecordDate,
    required this.onTapWearLog,
  });
  final List<WearLog> wearLogs;
  final ValueChanged<DateTime> onRecordDate;
  final ValueChanged<WearLog> onTapWearLog;

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
    final logsByDay = <int, WearLog>{
      for (final log in widget.wearLogs
        .where((log) => log.wornDate.year == _month.year && log.wornDate.month == _month.month)
      ) log.wornDate.day: log,
    };
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    final canGoNext = _month.isBefore(currentMonth);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_month.year}年 ${_month.month}月',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: canGoNext
                      ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
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
                final date = DateTime(_month.year, _month.month, day);
                final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
                if (isFuture) return const SizedBox.shrink();
                final wearLog = logsByDay[day];
                final worn = wearLog != null;
                return Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: wearLog == null
                        ? () => widget.onRecordDate(date)
                        : () => widget.onTapWearLog(wearLog),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: worn ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                      child: Text('$day'),
                    ),
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
