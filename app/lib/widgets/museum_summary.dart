import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/shoe.dart';
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
    return _SummaryCard(
      label: 'PAIRS',
      value: shoes.length.toString(),
      icon: Icons.inventory_2_outlined,
      onTap: () => _openCollection(ref),
    );
  }

  void _openCollection(WidgetRef ref) {
    ref.read(bottomNavigationIndexProvider.notifier).state = 3;
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
