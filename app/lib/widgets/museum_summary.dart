import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/collection_filter_provider.dart';
import '../providers/navigation_provider.dart';

class MuseumSummary extends ConsumerWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const MuseumSummary({
    super.key,
    required this.shoes,
    required this.brands,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandCount = shoes.map((shoe) => shoe.brandId).toSet().length;
    final favoriteCount = shoes.where((shoe) => shoe.isFavorite).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'PAIRS',
            value: shoes.length.toString(),
            icon: Icons.inventory_2_outlined,
            onTap: () => _openCollection(ref),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'BRANDS',
            value: brandCount.toString(),
            icon: Icons.sell_outlined,
            onTap: () => _selectBrand(context, ref),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'FAVORITES',
            value: favoriteCount.toString(),
            icon: Icons.favorite_outline,
            onTap: () {
              ref.read(collectionFilterProvider.notifier).state =
                  const CollectionFilter(favoritesOnly: true);
              ref.read(bottomNavigationIndexProvider.notifier).state = 1;
            },
          ),
        ),
      ],
    );
  }

  void _openCollection(WidgetRef ref) {
    ref.read(collectionFilterProvider.notifier).state =
        const CollectionFilter();
    ref.read(bottomNavigationIndexProvider.notifier).state = 1;
  }

  Future<void> _selectBrand(BuildContext context, WidgetRef ref) async {
    final availableBrands = brands
        .where((brand) => shoes.any((shoe) => shoe.brandId == brand.id))
        .toList();
    final brandId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('ブランドを選択')),
            ...availableBrands.map(
              (brand) => ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: Text(brand.name),
                trailing: Text(
                  shoes
                      .where((shoe) => shoe.brandId == brand.id)
                      .length
                      .toString(),
                ),
                onTap: () => Navigator.of(context).pop(brand.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (brandId == null) {
      return;
    }
    ref.read(collectionFilterProvider.notifier).state =
        CollectionFilter(brandId: brandId);
    ref.read(bottomNavigationIndexProvider.notifier).state = 1;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
