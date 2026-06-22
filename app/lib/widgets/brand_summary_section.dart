import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../models/shoe.dart';

class BrandSummarySection extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const BrandSummarySection({
    super.key,
    required this.shoes,
    required this.brands,
  });

  @override
  Widget build(BuildContext context) {
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };
    final counts = <int, int>{};
    for (final shoe in shoes) {
      counts.update(shoe.brandId, (count) => count + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ブランド別所有数', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text(
            'コレクションを追加するとブランド内訳が表示されます',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(brandNames[entry.key] ?? 'Unknown'),
                      ),
                      Text('${entry.value}足'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: shoes.isEmpty ? 0 : entry.value / shoes.length,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
