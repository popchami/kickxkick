import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shoe_card.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('検索は今後のSprintで実装予定です')),
              );
            },
          ),
        ],
      ),
      body: shoesAsync.when(
        data: (shoes) {
          if (shoes.isEmpty) {
            return EmptyState(
              icon: Icons.collections_outlined,
              title: 'あなたのコレクションはまだありません',
              description: '最初の一足を登録しましょう',
              actionLabel: '最初の一足を登録',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ShoeFormScreen(),
                  ),
                );
              },
            );
          }

          return brandsAsync.when(
            data: (brands) => _ShoeGrid(shoes: shoes, brands: brands),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ShoeGrid(shoes: shoes, brands: const []),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }
}

class _ShoeGrid extends ConsumerWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const _ShoeGrid({required this.shoes, required this.brands});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandNames = {
      for (final brand in brands) if (brand.id != null) brand.id!: brand.name,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        return ShoeCard(
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
          modelName: shoe.modelName,
          size: shoe.size ?? '-',
          color: shoe.color ?? '',
          isFavorite: shoe.isFavorite,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
              ),
            );
          },
          onFavoriteTap: () async {
            await ref.read(shoeRepositoryProvider).toggleFavorite(
                  shoe.id!,
                  !shoe.isFavorite,
                );
            ref.invalidate(shoesProvider);
          },
        );
      },
    );
  }
}
