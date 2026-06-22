import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand.dart';
import '../models/photo.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/photo_storage_provider.dart';
import '../providers/shoe_provider.dart';
import 'shoe_form_screen.dart';

class ShoeDetailScreen extends ConsumerWidget {
  final int shoeId;

  const ShoeDetailScreen({super.key, required this.shoeId});

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, Shoe shoe) async {
    final repository = ref.read(shoeRepositoryProvider);
    await repository.toggleFavorite(shoe.id!, !shoe.isFavorite);
    ref.invalidate(shoesProvider);
    ref.invalidate(shoeByIdProvider(shoe.id!));
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref, Shoe shoe) async {
    final photoType = await _selectPhotoType(context);
    if (photoType == null) {
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    try {
      final filePath = await ref.read(photoStorageServiceProvider).savePhoto(
            sourceFile: File(pickedFile.path),
            shoeId: shoe.id!,
            photoType: photoType,
          );

      await ref.read(photoRepositoryProvider).insertPhoto(
            Photo.create(
              shoeId: shoe.id!,
              photoType: photoType,
              filePath: filePath,
            ),
          );

      ref.invalidate(photosByShoeIdProvider(shoe.id!));
      ref.invalidate(mainPhotoProvider(shoe.id!));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を追加しました')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真の追加に失敗しました')),
        );
      }
    }
  }

  Future<PhotoType?> _selectPhotoType(BuildContext context) {
    return showModalBottomSheet<PhotoType>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('メイン写真'),
                subtitle: const Text('Collection画面で表示する写真'),
                onTap: () => Navigator.of(context).pop(PhotoType.main),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('ギャラリー写真'),
                subtitle: const Text('Detail画面で表示する追加写真'),
                onTap: () => Navigator.of(context).pop(PhotoType.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('箱写真'),
                subtitle: const Text('箱や付属品の記録写真'),
                onTap: () => Navigator.of(context).pop(PhotoType.box),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteShoe(BuildContext context, WidgetRef ref, Shoe shoe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('このスニーカーを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(shoeRepositoryProvider).deleteShoe(shoe.id!);
      ref.invalidate(shoesProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoeAsync = ref.watch(shoeByIdProvider(shoeId));
    final brandsAsync = ref.watch(brandsProvider);

    return shoeAsync.when(
      data: (shoe) {
        if (shoe == null) {
          return const Scaffold(
            body: Center(child: Text('スニーカーが見つかりません')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(shoe.modelName),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: () => _addPhoto(context, ref, shoe),
              ),
              IconButton(
                icon: Icon(shoe.isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () => _toggleFavorite(context, ref, shoe),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShoeFormScreen(shoe: shoe),
                    ),
                  );
                  ref.invalidate(shoeByIdProvider(shoeId));
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteShoe(context, ref, shoe),
              ),
            ],
          ),
          body: brandsAsync.when(
            data: (brands) => _DetailBody(
              shoe: shoe,
              brand: _findBrand(brands, shoe.brandId),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _DetailBody(shoe: shoe, brand: null),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('読み込みに失敗しました'))),
    );
  }

  Brand? _findBrand(List<Brand> brands, int brandId) {
    for (final brand in brands) {
      if (brand.id == brandId) {
        return brand;
      }
    }
    return null;
  }
}

class _DetailBody extends ConsumerWidget {
  final Shoe shoe;
  final Brand? brand;

  const _DetailBody({required this.shoe, required this.brand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final photosAsync = ref.watch(photosByShoeIdProvider(shoe.id!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        mainPhotoAsync.when(
          data: (photo) => _MainPhoto(photo: photo),
          loading: () => const _PhotoPlaceholder(label: '写真を読み込み中'),
          error: (_, __) => const _PhotoPlaceholder(label: '写真を読み込めませんでした'),
        ),
        const SizedBox(height: 24),
        photosAsync.when(
          data: (photos) => _PhotoSections(photos: photos),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('写真一覧を読み込めませんでした'),
        ),
        const SizedBox(height: 24),
        _InfoTile(label: 'ブランド', value: brand?.name ?? 'Unknown'),
        _InfoTile(label: 'モデル名', value: shoe.modelName),
        _InfoTile(label: 'サイズ', value: shoe.size),
        _InfoTile(label: 'カラー', value: shoe.color),
        _InfoTile(label: '購入日', value: _formatDate(shoe.purchaseDate)),
        _InfoTile(label: '購入価格', value: shoe.purchasePrice == null ? null : '${shoe.purchasePrice}円'),
        _InfoTile(label: '購入店', value: shoe.purchaseStore),
        _InfoTile(label: 'メモ', value: shoe.memo),
        _InfoTile(label: 'お気に入り', value: shoe.isFavorite ? 'ON' : 'OFF'),
        _InfoTile(label: '登録日', value: _formatDate(shoe.createdAt)),
        _InfoTile(label: '更新日', value: _formatDate(shoe.updatedAt)),
      ],
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return '${date.year}/${date.month}/${date.day}';
  }
}

class _MainPhoto extends StatelessWidget {
  final Photo? photo;

  const _MainPhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo == null) {
      return const _PhotoPlaceholder(label: 'メイン写真を追加できます');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.file(
        File(photo.filePath),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PhotoPlaceholder(label: '写真ファイルが見つかりません'),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String label;

  const _PhotoPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _PhotoSections extends StatelessWidget {
  final List<Photo> photos;

  const _PhotoSections({required this.photos});

  @override
  Widget build(BuildContext context) {
    final galleryPhotos = photos.where((photo) => photo.photoType == PhotoType.gallery).toList();
    final boxPhotos = photos.where((photo) => photo.photoType == PhotoType.box).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhotoStrip(title: 'ギャラリー写真', photos: galleryPhotos),
        const SizedBox(height: 20),
        _PhotoStrip(title: '箱写真', photos: boxPhotos),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final String title;
  final List<Photo> photos;

  const _PhotoStrip({required this.title, required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Text(
        '$titleは未登録です',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(photo.filePath),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null || value!.isEmpty ? '未設定' : value!),
    );
  }
}
