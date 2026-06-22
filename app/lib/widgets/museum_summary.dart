import 'package:flutter/material.dart';

import '../models/shoe.dart';

class MuseumSummary extends StatelessWidget {
  final List<Shoe> shoes;

  const MuseumSummary({super.key, required this.shoes});

  @override
  Widget build(BuildContext context) {
    final brandCount = shoes.map((shoe) => shoe.brandId).toSet().length;
    final favoriteCount = shoes.where((shoe) => shoe.isFavorite).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'PAIRS',
            value: shoes.length.toString(),
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'BRANDS',
            value: brandCount.toString(),
            icon: Icons.sell_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'FAVORITES',
            value: favoriteCount.toString(),
            icon: Icons.favorite_outline,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
