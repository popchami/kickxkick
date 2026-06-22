import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/recent_worn_section.dart';
import '../widgets/shoe_card.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SoleMuseum'),
            Text(
              'Collect. Preserve. Showcase.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: shoesAsync.when(
        data: (shoes) => brandsAsync.when(
          data: (brands) => _HomeContent(shoes: shoes, brands: brands),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _HomeContent(shoes: shoes, brands: const []),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const _HomeContent({required this.shoes, required this.brands});

  @override
  Widget build(BuildContext context) {
    final recentShoes = shoes.take(3).toList();
    final brandNames = {
      for (final brand in brands) if (brand.id != null) brand.id!: brand.name,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('MY COLLECTION', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          '${shoes.length} PAIRS',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text('最近追加', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (recentShoes.isEmpty)
          EmptyState(
            icon: Icons.home_outlined,
            title: 'あなたのコレクションはまだありません',
            description: '最初の一足を登録しましょう',
            actionLabel: '最初の一足を登録',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
              );
            },
          )
        else
          ...recentShoes.map(
            (shoe) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShoeCard(
                brandName: brandNames[shoe.brandId] ?? 'Unknown',
                modelName: shoe.modelName,
                size: shoe.size ?? '-',
                color: shoe.color ?? '',
                isFavorite: shoe.isFavorite,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ShoeDetailScreen(shoeId: shoe.id!)),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 24),
        RecentWornSection(shoes: shoes, brands: brands),
        const SizedBox(height: 24),
        Text('MY TOP 5', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Sprint3以降で実装予定です'),
        const SizedBox(height: 24),
        Text('ブランド別所有数', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Sprint3以降で実装予定です'),
      ],
    );
  }
}
