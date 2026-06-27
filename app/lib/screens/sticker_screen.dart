import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brand.dart';
import '../models/photo.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/empty_state.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

class StickerScreen extends ConsumerWidget {
  const StickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker'),
      ),
      body: shoesAsync.when(
        data: (shoes) => brandsAsync.when(
          data: (brands) => _StickerContent(shoes: shoes, brands: brands),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _StickerContent(shoes: shoes, brands: const []),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }
}

class _StickerContent extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;

  const _StickerContent({required this.shoes, required this.brands});

  @override
  Widget build(BuildContext context) {
    if (shoes.isEmpty) {
      return EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'まだステッカーがありません',
        description: 'スニーカーを登録すると、ここにステッカーとして並びます',
        actionLabel: 'スニーカーを登録',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
          );
        },
      );
    }

    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        return _StickerCard(
          shoe: shoe,
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
        );
      },
    );
  }
}

class _StickerCard extends ConsumerWidget {
  final Shoe shoe;
  final String brandName;

  const _StickerCard({required this.shoe, required this.brandName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final photo = mainPhotoAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final stickerText = _stickerLabel(shoe);
    final title = shoe.displayTitle?.isNotEmpty == true
        ? shoe.displayTitle!
        : shoe.modelName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StickerPhoto(photo: photo),
                ),
                const SizedBox(height: 10),
                Text(
                  stickerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stickerLabel(Shoe shoe) {
    final text = shoe.stickerText?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
    final displayTitle = shoe.displayTitle?.trim();
    if (displayTitle != null && displayTitle.isNotEmpty) {
      return displayTitle;
    }
    return shoe.modelName;
  }
}

class _StickerPhoto extends StatelessWidget {
  final Photo? photo;

  const _StickerPhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    final imagePath = photo?.filePath;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imagePath == null || imagePath.isEmpty
            ? const Center(child: Icon(Icons.image_outlined, size: 48))
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
      ),
    );
  }
}
