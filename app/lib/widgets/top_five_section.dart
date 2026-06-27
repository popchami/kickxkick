import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';

class TopFiveSection extends ConsumerWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const TopFiveSection({
    super.key,
    required this.shoes,
    required this.brands,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byRank = {
      for (final shoe in shoes)
        if (shoe.topOrder != null) shoe.topOrder!: shoe,
    };
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined),
            const SizedBox(width: 8),
            Text('MY TOP 5', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('${byRank.length}/5'),
          ],
        ),
        const SizedBox(height: 12),
        _RankSlot(
          rank: 1,
          shoe: byRank[1],
          brandName: byRank[1] == null ? null : brandNames[byRank[1]!.brandId],
          height: 260,
          onTap: () => _selectShoe(context, ref, 1),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final rank = index + 2;
            final shoe = byRank[rank];
            return _RankSlot(
              rank: rank,
              shoe: shoe,
              brandName: shoe == null ? null : brandNames[shoe.brandId],
              onTap: () => _selectShoe(context, ref, rank),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectShoe(BuildContext context, WidgetRef ref, int rank) async {
    final selected = await showDialog<Shoe>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$rank位のスニーカー'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shoes.length,
            itemBuilder: (context, index) {
              final shoe = shoes[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${shoe.topOrder ?? '−'}')),
                title: Text(shoe.displayTitle?.isNotEmpty == true
                    ? shoe.displayTitle!
                    : shoe.modelName),
                onTap: () => Navigator.pop(context, shoe),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null) return;
    await ref.read(shoeRepositoryProvider).setTopOrder(selected.id!, rank);
    ref.invalidate(shoesProvider);
  }
}

class _RankSlot extends StatelessWidget {
  const _RankSlot({
    required this.rank,
    required this.shoe,
    required this.brandName,
    required this.onTap,
    this.height,
  });

  final int rank;
  final Shoe? shoe;
  final String? brandName;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final value = shoe;
    if (value == null) {
      return SizedBox(
        height: height,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$rank', style: Theme.of(context).textTheme.headlineMedium),
                  const Icon(Icons.add_circle_outline),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: _TopFiveCard(
        rank: rank,
        shoe: value,
        brandName: brandName ?? 'Unknown',
        onTap: onTap,
      ),
    );
  }
}

class _TopFiveCard extends ConsumerWidget {
  final int rank;
  final Shoe shoe;
  final String brandName;
  final VoidCallback onTap;

  const _TopFiveCard({
    required this.rank,
    required this.shoe,
    required this.brandName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final imagePath = mainPhotoAsync.maybeWhen(
      data: (photo) => photo?.filePath,
      orElse: () => null,
    );

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TopFiveImage(imagePath: imagePath),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          '$rank',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe.displayTitle?.isNotEmpty == true
                          ? shoe.displayTitle!
                          : shoe.modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopFiveImage extends StatelessWidget {
  final String? imagePath;

  const _TopFiveImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_outlined, size: 48)),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
