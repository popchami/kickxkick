import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shoe.dart';
import '../models/wear_log.dart';
import '../providers/brand_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';

class TodayWornAction extends ConsumerWidget {
  const TodayWornAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => _openPicker(context, ref),
        icon: const Icon(Icons.directions_walk),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text('今日履いたスニーカーを記録'),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final shoe = await showModalBottomSheet<Shoe>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TodayWornPicker(),
    );
    if (shoe != null && context.mounted) {
      await _recordWear(context, ref, shoe);
    }
  }

  Future<void> _recordWear(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    var memoText = '';
    final shoeTitle = shoe.displayTitle?.isNotEmpty == true
        ? shoe.displayTitle!
        : shoe.modelName;
    final memo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$shoeTitle\n今日の着用記録'),
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

    final messenger = ScaffoldMessenger.of(context);
    try {
      final inserted = await ref.read(wearLogRepositoryProvider).insertWearLog(
            WearLog.create(
              shoeId: shoe.id!,
              wornDate: DateTime.now(),
              memo: memo.isEmpty ? null : memo,
            ),
          );
      if (inserted) {
        await ref.read(shoeRepositoryProvider).markWornIfNew(shoe.id!);
      }
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider(shoe.id!));
      ref.invalidate(wearLogsByShoeIdProvider(shoe.id!));
      ref.invalidate(recentWearLogsProvider);
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              inserted ? '$shoeTitleの着用を記録しました' : '今日はすでに記録済みです',
            ),
          ),
        );
      }
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('着用記録の保存に失敗しました')),
        );
      }
    }
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
              '今日履いたスニーカーを選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: shoesAsync.when(
              data: (shoes) => brandsAsync.when(
                data: (brands) {
                  if (shoes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'スニーカーが登録されていません',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final brandNames = {
                    for (final brand in brands)
                      if (brand.id != null) brand.id!: brand.name,
                  };
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: shoes.length,
                    itemBuilder: (context, index) {
                      final shoe = shoes[index];
                      final title = shoe.displayTitle?.isNotEmpty == true
                          ? shoe.displayTitle!
                          : shoe.modelName;
                      return ListTile(
                        title: Text(title),
                        subtitle: Text(brandNames[shoe.brandId] ?? ''),
                        trailing: Text(shoe.archiveNumber),
                        onTap: () => Navigator.of(context).pop(shoe),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('読み込めませんでした')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('読み込めませんでした')),
            ),
          ),
        ],
      ),
    );
  }
}
