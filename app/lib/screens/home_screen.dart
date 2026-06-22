import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_summary_section.dart';
import '../widgets/empty_state.dart';
import '../widgets/museum_summary.dart';
import '../widgets/recent_worn_section.dart';
import '../widgets/top_five_section.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';
import 'wear_stats_screen.dart';

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
            const Text(AppTheme.appName),
            Text(
              AppTheme.tagline,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: '着用統計',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WearStatsScreen()),
            ),
          ),
        ],
      ),
      body: shoesAsync.when(
        data: (shoes) {
          Future<void> onRefresh() async {
            ref.invalidate(shoesProvider);
            ref.invalidate(brandsProvider);
            ref.invalidate(recentWearLogsProvider);
            ref.invalidate(allWearLogsProvider);
            await ref.read(shoesProvider.future);
          }

          return brandsAsync.when(
            data: (brands) => _HomeContent(
              shoes: shoes,
              brands: brands,
              onRefresh: onRefresh,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _HomeContent(
              shoes: shoes,
              brands: const [],
              onRefresh: onRefresh,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;
  final Future<void> Function() onRefresh;

  const _HomeContent({
    required this.shoes,
    required this.brands,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ownedShoes = shoes.where((s) => s.status == ShoeStatus.owned).toList();
    final wishlistShoes = shoes.where((s) => s.status == ShoeStatus.wishlist).toList();
    final recentShoes = ownedShoes.take(6).toList();
    final featuredShoe = ownedShoes.isNotEmpty
        ? ownedShoes.firstWhere((s) => s.topOrder == 1, orElse: () => ownedShoes.first)
        : null;
    final brandNames = {
      for (final brand in brands) if (brand.id != null) brand.id!: brand.name,
    };

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('MY COLLECTION', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        MuseumSummary(shoes: ownedShoes),
        if (featuredShoe != null) ...[
          const SizedBox(height: 24),
          Text('注目の展示', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _FeaturedShoe(
            shoe: featuredShoe,
            brandName: brandNames[featuredShoe.brandId] ?? 'Unknown',
          ),
        ],
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
          _RecentGrid(shoes: recentShoes, brandNames: brandNames),
        const SizedBox(height: 24),
        RecentWornSection(shoes: ownedShoes, brands: brands),
        const SizedBox(height: 24),
        TopFiveSection(shoes: ownedShoes, brands: brands),
        if (wishlistShoes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('ほしいリスト', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${wishlistShoes.length}足',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          _WishlistSection(shoes: wishlistShoes, brandNames: brandNames),
        ],
        const SizedBox(height: 24),
        BrandSummarySection(shoes: ownedShoes, brands: brands),
      ],
    ),
    );
  }
}

class _FeaturedShoe extends ConsumerWidget {
  final Shoe shoe;
  final String brandName;

  const _FeaturedShoe({required this.shoe, required this.brandName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final imagePath = mainPhotoAsync.maybeWhen(
      data: (photo) => photo?.filePath,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ShoeDetailScreen(shoeId: shoe.id!)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                Image.file(File(imagePath), fit: BoxFit.cover)
              else
                ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.image_outlined, size: 64)),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shoe.archiveNumber,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        brandName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        shoe.modelName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  final List<Shoe> shoes;
  final Map<int, String> brandNames;

  const _RecentGrid({required this.shoes, required this.brandNames});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        return _RecentGridCell(
          shoe: shoe,
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
        );
      },
    );
  }
}

class _RecentGridCell extends ConsumerWidget {
  final Shoe shoe;
  final String brandName;

  const _RecentGridCell({required this.shoe, required this.brandName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final imagePath = mainPhotoAsync.maybeWhen(
      data: (photo) => photo?.filePath,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ShoeDetailScreen(shoeId: shoe.id!)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              Image.file(File(imagePath), fit: BoxFit.cover)
            else
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.image_outlined)),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xAA000000), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brandName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      shoe.modelName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistSection extends StatelessWidget {
  final List<Shoe> shoes;
  final Map<int, String> brandNames;

  const _WishlistSection({required this.shoes, required this.brandNames});

  @override
  Widget build(BuildContext context) {
    final displayShoes = shoes.take(5).toList();
    return Column(
      children: [
        ...displayShoes.map((shoe) {
          final brandName = brandNames[shoe.brandId] ?? 'Unknown';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_outlined),
            title: Text(
              '$brandName  ${shoe.modelName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              shoe.archiveNumber,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
              ),
            ),
          );
        }),
        if (shoes.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'ほか ${shoes.length - 5}足',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
      ],
    );
  }
}
