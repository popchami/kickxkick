import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/wear_log_provider.dart';
import '../screens/shoe_detail_screen.dart';

class RecentWornSection extends ConsumerWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const RecentWornSection({
    super.key,
    required this.shoes,
    required this.brands,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentWearLogsAsync = ref.watch(recentWearLogsProvider);
    final shoesById = {
      for (final shoe in shoes)
        if (shoe.id != null) shoe.id!: shoe,
    };
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近履いた', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        recentWearLogsAsync.when(
          data: (wearLogs) {
            final visibleLogs = wearLogs
                .where((wearLog) => shoesById.containsKey(wearLog.shoeId))
                .take(3)
                .toList();

            if (visibleLogs.isEmpty) {
              return Text(
                '着用記録はまだありません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              );
            }

            return Column(
              children: visibleLogs.map((wearLog) {
                final shoe = shoesById[wearLog.shoeId]!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.directions_walk),
                  ),
                  title: Text(shoe.modelName),
                  subtitle: Text(
                    '${brandNames[shoe.brandId] ?? 'Unknown'} • '
                    '${wearLog.wornDate.year}/${wearLog.wornDate.month}/${wearLog.wornDate.day}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('着用記録を読み込めませんでした'),
        ),
      ],
    );
  }
}
