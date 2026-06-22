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
import '../widgets/wear_history_section.dart';
import 'shoe_form_screen.dart';

class ShoeDetailScreen extends ConsumerWidget {
  final int shoeId;

  const ShoeDetailScreen({super.key, required this.shoeId});

  Future<void> _toggleFavorite(
      BuildContext context, WidgetRef ref, Shoe shoe) async {
    final repository = ref.read(shoeRepositoryProvider);
    await repository.toggleFavorite(shoe.id!, !shoe.isFavorite);
    ref.invalidate(shoesProvider);
    ref.invalidate(shoeByIdProvider(shoe.id!));
  }

  Future<void> _toggleTopFive(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final shouldSelect = shoe.topOrder == null;
    final updated = await ref
        .read(shoeRepositoryProvider)
        .setTopFive(shoe.id!, shouldSelect);

    if (updated) {
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider(shoe.id!));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? shouldSelect
                    ? 'MY TOP 5に追加しました'
                    : 'MY TOP 5から外しました'
                : shouldSelect
                    ? 'MY TOP 5は5足までです'
                    : 'MY TOP 5の更新に失敗しました',
          ),
        ),
      );
    }
  }

  Future<void> _addPhoto(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
    PhotoType photoType,
  ) async {
    if (photoType == PhotoType.gallery) {
      await _addGalleryPhotos(context, ref, shoe);
      return;
    }

    final repository = ref.read(photoRepositoryProvider);
    if (photoType == PhotoType.main) {
      final currentMainPhoto = await repository.getMainPhoto(shoe.id!);
      if (currentMainPhoto != null && context.mounted) {
        final confirmed = await _confirmMainPhotoReplacement(context);
        if (confirmed != true) {
          return;
        }
      }
    }

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    try {
      final filePath = await ref.read(photoStorageServiceProvider).savePhoto(
            sourceFile: File(pickedFile.path),
            shoeId: shoe.id!,
            photoType: photoType,
          );

      final photo = Photo.create(
        shoeId: shoe.id!,
        photoType: photoType,
        filePath: filePath,
      );

      if (photoType == PhotoType.main) {
        final previousPhotos = await repository.replaceMainPhoto(photo);
        for (final previousPhoto in previousPhotos) {
          try {
            await ref
                .read(photoStorageServiceProvider)
                .deletePhotoFile(previousPhoto.filePath);
          } catch (_) {
            // The database replacement succeeded; stale file cleanup is best effort.
          }
        }
      } else {
        await repository.insertPhoto(photo);
      }

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

  Future<void> _addGalleryPhotos(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    const maxGalleryPhotos = 10;
    final repository = ref.read(photoRepositoryProvider);
    final currentPhotos = await repository.getPhotosByShoeId(shoe.id!);
    final galleryCount = currentPhotos
        .where((photo) => photo.photoType == PhotoType.gallery)
        .length;
    final remaining = maxGalleryPhotos - galleryCount;
    if (remaining <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ギャラリーは10枚までです')),
        );
      }
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage(limit: remaining);
    if (pickedFiles.isEmpty) {
      return;
    }
    final selectedFiles = pickedFiles.take(remaining).toList();

    try {
      for (final pickedFile in selectedFiles) {
        final filePath = await ref.read(photoStorageServiceProvider).savePhoto(
              sourceFile: File(pickedFile.path),
              shoeId: shoe.id!,
              photoType: PhotoType.gallery,
            );
        await repository.insertPhoto(
          Photo.create(
            shoeId: shoe.id!,
            photoType: PhotoType.gallery,
            filePath: filePath,
          ),
        );
      }
      ref.invalidate(photosByShoeIdProvider(shoe.id!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedFiles.length}枚追加しました')),
        );
      }
    } catch (_) {
      ref.invalidate(photosByShoeIdProvider(shoe.id!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真の追加に失敗しました')),
        );
      }
    }
  }

  Future<bool?> _confirmMainPhotoReplacement(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メイン写真を変更しますか？'),
        content: const Text(
          '新しい写真を選ぶと、現在のメイン写真は削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('写真を変更'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShoe(
      BuildContext context, WidgetRef ref, Shoe shoe) async {
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
                icon: Icon(
                    shoe.isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () => _toggleFavorite(context, ref, shoe),
              ),
              IconButton(
                tooltip: shoe.topOrder == null ? 'MY TOP 5に追加' : 'MY TOP 5から外す',
                icon: Icon(
                  shoe.topOrder == null
                      ? Icons.emoji_events_outlined
                      : Icons.emoji_events,
                ),
                onPressed: () => _toggleTopFive(context, ref, shoe),
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
              onAddPhoto: (type) => _addPhoto(context, ref, shoe, type),
              onToggleFavorite: () => _toggleFavorite(context, ref, shoe),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _DetailBody(
              shoe: shoe,
              brand: null,
              onAddPhoto: (type) => _addPhoto(context, ref, shoe, type),
              onToggleFavorite: () => _toggleFavorite(context, ref, shoe),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) =>
          const Scaffold(body: Center(child: Text('読み込みに失敗しました'))),
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
  final ValueChanged<PhotoType> onAddPhoto;
  final VoidCallback onToggleFavorite;

  const _DetailBody({
    required this.shoe,
    required this.brand,
    required this.onAddPhoto,
    required this.onToggleFavorite,
  });

  Future<void> _deletePhoto(
      BuildContext context, WidgetRef ref, Photo photo) async {
    final photoId = photo.id;
    if (photoId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除しますか？'),
        content: const Text('この写真を削除します。\nこの操作は取り消せません。'),
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
      await ref.read(photoRepositoryProvider).deletePhoto(photoId);
      await ref
          .read(photoStorageServiceProvider)
          .deletePhotoFile(photo.filePath);
      ref.invalidate(photosByShoeIdProvider(shoe.id!));
      ref.invalidate(mainPhotoProvider(shoe.id!));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を削除しました')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真の削除に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final photosAsync = ref.watch(photosByShoeIdProvider(shoe.id!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        mainPhotoAsync.when(
          data: (photo) => _InteractiveMainPhoto(
            photo: photo,
            onAdd: () => onAddPhoto(PhotoType.main),
            onChange: () => onAddPhoto(PhotoType.main),
            onDelete:
                photo == null ? null : () => _deletePhoto(context, ref, photo),
          ),
          loading: () => const _PhotoPlaceholder(label: '写真を読み込み中'),
          error: (_, __) => const _PhotoPlaceholder(label: '写真を読み込めませんでした'),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              shoe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: shoe.isFavorite ? Colors.red : null,
            ),
            title: Text(shoe.isFavorite ? 'お気に入り登録済み' : 'お気に入りに追加'),
            trailing: Switch(
              value: shoe.isFavorite,
              onChanged: (_) => onToggleFavorite(),
            ),
            onTap: onToggleFavorite,
          ),
        ),
        const SizedBox(height: 24),
        photosAsync.when(
          data: (photos) => _InteractivePhotoSections(
            photos: photos,
            onDeletePhoto: (photo) => _deletePhoto(context, ref, photo),
            onAddGallery: () => onAddPhoto(PhotoType.gallery),
            onAddBox: () => onAddPhoto(PhotoType.box),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('写真一覧を読み込めませんでした'),
        ),
        const SizedBox(height: 24),
        WearHistorySection(shoeId: shoe.id!),
        const SizedBox(height: 24),
        _InfoTile(label: 'ブランド', value: brand?.name ?? 'Unknown'),
        _InfoTile(label: 'アーカイブ番号', value: shoe.archiveNumber),
        _InfoTile(label: 'モデル名', value: shoe.modelName),
        _InfoTile(label: 'サイズ', value: shoe.size),
        _InfoTile(label: 'カラー', value: shoe.color),
        _InfoTile(label: '購入日', value: _formatDate(shoe.purchaseDate)),
        _InfoTile(
            label: '購入価格',
            value:
                shoe.purchasePrice == null ? null : '${shoe.purchasePrice}円'),
        _InfoTile(label: '購入店', value: shoe.purchaseStore),
        _InfoTile(label: 'メモ', value: shoe.memo),
        _InfoTile(label: 'お気に入り', value: shoe.isFavorite ? 'ON' : 'OFF'),
        _InfoTile(
          label: 'MY TOP 5',
          value: shoe.topOrder == null ? '未選択' : 'No. ${shoe.topOrder}',
        ),
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

class _InteractiveMainPhoto extends StatelessWidget {
  final Photo? photo;
  final VoidCallback onAdd;
  final VoidCallback onChange;
  final VoidCallback? onDelete;

  const _InteractiveMainPhoto({
    required this.photo,
    required this.onAdd,
    required this.onChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    if (currentPhoto == null) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 56),
              SizedBox(height: 12),
              Text('メイン写真を追加'),
              SizedBox(height: 4),
              Text('タップして写真を選択'),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onDelete,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(
              File(currentPhoto.filePath),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(
                label: '写真ファイルが見つかりません',
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: FilledButton.tonalIcon(
              onPressed: onChange,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('変更'),
            ),
          ),
          const Positioned(
            right: 12,
            bottom: 12,
            child: _DeleteHintChip(),
          ),
        ],
      ),
    );
  }
}

class _InteractivePhotoSections extends StatelessWidget {
  static const int maxGalleryPhotos = 10;

  final List<Photo> photos;
  final ValueChanged<Photo> onDeletePhoto;
  final VoidCallback onAddGallery;
  final VoidCallback onAddBox;

  const _InteractivePhotoSections({
    required this.photos,
    required this.onDeletePhoto,
    required this.onAddGallery,
    required this.onAddBox,
  });

  @override
  Widget build(BuildContext context) {
    final galleryPhotos =
        photos.where((photo) => photo.photoType == PhotoType.gallery).toList();
    final boxPhotos =
        photos.where((photo) => photo.photoType == PhotoType.box).toList();
    final remaining = maxGalleryPhotos - galleryPhotos.length;

    return Column(
      children: [
        _InteractivePhotoStrip(
          title: 'ギャラリー',
          subtitle: remaining > 0
              ? '${galleryPhotos.length}/$maxGalleryPhotos枚・あと$remaining枚'
              : '$maxGalleryPhotos/$maxGalleryPhotos枚・上限に達しました',
          photos: galleryPhotos,
          onAdd: remaining > 0 ? onAddGallery : null,
          onDeletePhoto: onDeletePhoto,
        ),
        const SizedBox(height: 20),
        _InteractivePhotoStrip(
          title: '箱・付属品',
          subtitle: '${boxPhotos.length}枚',
          photos: boxPhotos,
          onAdd: onAddBox,
          onDeletePhoto: onDeletePhoto,
        ),
      ],
    );
  }
}

class _InteractivePhotoStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Photo> photos;
  final VoidCallback? onAdd;
  final ValueChanged<Photo> onDeletePhoto;

  const _InteractivePhotoStrip({
    required this.title,
    required this.subtitle,
    required this.photos,
    required this.onAdd,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('写真を追加'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          Text(
            'まだ写真がありません',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onLongPress: () => onDeletePhoto(photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(photo.filePath),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 96,
                        height: 96,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
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

class _DeleteHintChip extends StatelessWidget {
  const _DeleteHintChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 16),
            SizedBox(width: 4),
            Text('長押しで削除'),
          ],
        ),
      ),
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
