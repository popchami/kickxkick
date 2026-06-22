import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wear_log.dart';
import '../providers/wear_log_provider.dart';

class WearHistorySection extends ConsumerWidget {
  final int shoeId;

  const WearHistorySection({super.key, required this.shoeId});

  Future<void> _recordWear(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(DateTime, String)>(
      context: context,
      builder: (context) => _WearLogDialog(),
    );
    if (result == null) return;

    final (date, memo) = result;

    try {
      final inserted = await ref.read(wearLogRepositoryProvider).insertWearLog(
            WearLog.create(
              shoeId: shoeId,
              wornDate: date,
              memo: memo.isEmpty ? null : memo,
            ),
          );
      ref.invalidate(wearLogsByShoeIdProvider(shoeId));
      ref.invalidate(recentWearLogsProvider);
      ref.invalidate(allWearLogsProvider);

      if (context.mounted) {
        final isToday = _isToday(date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inserted
                  ? isToday
                      ? '今日の着用を記録しました'
                      : '${_formatDate(date)}の着用を記録しました'
                  : 'その日はすでに記録済みです',
            ),
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

  Future<void> _editWearLog(
    BuildContext context,
    WidgetRef ref,
    WearLog wearLog,
  ) async {
    final id = wearLog.id;
    if (id == null) return;

    final controller = TextEditingController(text: wearLog.memo ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('メモを編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'メモ（任意）',
            hintText: '行き先や天気など',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('キャンセル'),
          ),
          if (wearLog.memo != null)
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(''),
              child: const Text('メモを削除'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dlgCtx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    final newMemo = result.isEmpty ? null : result;
    await ref.read(wearLogRepositoryProvider).updateWearLogMemo(id, newMemo);
    ref.invalidate(wearLogsByShoeIdProvider(shoeId));
    ref.invalidate(allWearLogsProvider);
  }

  Future<void> _deleteWearLog(
    BuildContext context,
    WidgetRef ref,
    WearLog wearLog,
  ) async {
    final id = wearLog.id;
    if (id == null) return;

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

    if (confirmed != true) return;

    await ref.read(wearLogRepositoryProvider).deleteWearLog(id);
    ref.invalidate(wearLogsByShoeIdProvider(shoeId));
    ref.invalidate(recentWearLogsProvider);
    ref.invalidate(allWearLogsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearLogsAsync = ref.watch(wearLogsByShoeIdProvider(shoeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _recordWear(context, ref),
          icon: const Icon(Icons.directions_walk),
          label: const Text('着用を記録'),
        ),
        const SizedBox(height: 20),
        Text(
          wearLogsAsync.maybeWhen(
            data: (logs) => logs.isNotEmpty ? '着用履歴（${logs.length}回）' : '着用履歴',
            orElse: () => '着用履歴',
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'メモを編集',
                              onPressed: () =>
                                  _editWearLog(context, ref, wearLog),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: '着用記録を削除',
                              onPressed: () =>
                                  _deleteWearLog(context, ref, wearLog),
                            ),
                          ],
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

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}/$mm/$dd';
  }
}

class _WearLogDialog extends StatefulWidget {
  const _WearLogDialog();

  @override
  State<_WearLogDialog> createState() => _WearLogDialogState();
}

class _WearLogDialogState extends State<_WearLogDialog> {
  DateTime _selectedDate = DateTime.now();
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return '今日';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}/$mm/$dd';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('着用を記録'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('日付'),
            subtitle: Text(_formatDate(_selectedDate)),
            onTap: _pickDate,
            trailing: const Icon(Icons.chevron_right, size: 18),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              labelText: 'メモ（任意）',
              hintText: '行き先や天気など',
            ),
            maxLines: 3,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (_selectedDate, _memoController.text.trim()),
          ),
          child: const Text('記録'),
        ),
      ],
    );
  }
}
