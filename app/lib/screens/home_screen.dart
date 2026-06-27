import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/brand_summary_section.dart';
import '../widgets/empty_state.dart';
import '../widgets/museum_summary.dart';
import '../widgets/recent_worn_section.dart';
import '../widgets/shoe_card.dart';
import '../widgets/top_five_section.dart';
import '../widgets/today_worn_action.dart';
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
            const Text('Kick×Kick'),
            Text(
              'Collect. Create. Exhibit.',
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
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TopFiveSection(shoes: shoes, brands: brands),
        const SizedBox(height: 24),
        Text('MY COLLECTION', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        MuseumSummary(shoes: shoes, brands: brands),
        const SizedBox(height: 16),
        const TodayWornAction(),
        const SizedBox(height: 24),
        Text('最近追加', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (recentShoes.isEmpty)
          EmptyState(
            icon: Icons.home_outlined,
            title: 'あなたのコレクションはまだありません',
            description: '最初のスニーカーを登録しましょう',
            actionLabel: '最初のスニーカーを登録',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
              );
            },
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentShoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final shoe = recentShoes[index];
                return SizedBox(
                  width: 140,
                  child: _RecentShoeCard(
                    shoe: shoe,
                    brandName: brandNames[shoe.brandId] ?? 'Unknown',
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        RecentWornSection(shoes: shoes, brands: brands),
        const SizedBox(height: 24),
        BrandSummarySection(shoes: shoes, brands: brands),
      ],
    );
  }
}

class _RecentShoeCard extends ConsumerWidget {
  final Shoe shoe;
  final String brandName;

  const _RecentShoeCard({required this.shoe, required this.brandName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final imagePath = mainPhotoAsync.maybeWhen(
      data: (photo) => photo?.filePath,
      orElse: () => null,
    );

    return ShoeCard(
      brandName: brandName,
      modelName: shoe.displayTitle?.isNotEmpty == true
          ? shoe.displayTitle!
          : shoe.modelName,
      size: shoe.size ?? '-',
      color: shoe.color ?? '',
      statusLabel: shoe.statusLabel,
      imagePath: imagePath,
      archiveNumber: shoe.archiveNumber,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
          ),
        );
      },
    );
  }
}
