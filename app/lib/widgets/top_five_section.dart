import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/photo_provider.dart';
import '../screens/shoe_detail_screen.dart';

class TopFiveSection extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const TopFiveSection({
    super.key,
    required this.shoes,
    required this.brands,
  });

  @override
  Widget build(BuildContext context) {
    final topShoes = shoes.where((shoe) => shoe.topOrder != null).toList()
      ..sort((a, b) => a.topOrder!.compareTo(b.topOrder!));
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
            Text('${topShoes.length}/5'),
          ],
        ),
        const SizedBox(height: 12),
        if (topShoes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '詳細画面のトロフィーから、展示したい5足を選べます。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topShoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shoe = topShoes[index];
                return _TopFiveCard(
                  rank: index + 1,
                  shoe: shoe,
                  brandName: brandNames[shoe.brandId] ?? 'Unknown',
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TopFiveCard extends ConsumerWidget {
  final int rank;
  final Shoe shoe;
  final String brandName;

  const _TopFiveCard({
    required this.rank,
    required this.shoe,
    required this.brandName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final imagePath = mainPhotoAsync.maybeWhen(
      data: (photo) => photo?.filePath,
      orElse: () => null,
    );

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
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
