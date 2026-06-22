import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/brand.dart';
import '../models/photo.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/photo_storage_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/wear_log_provider.dart';
import '../widgets/wear_history_section.dart';
import 'photo_viewer_screen.dart';
import 'shoe_form_screen.dart';

class ShoeDetailScreen extends ConsumerStatefulWidget {
  final int shoeId;
  final List<int>? shoeIds;

  const ShoeDetailScreen({
    super.key,
    required this.shoeId,
    this.shoeIds,
  });

  @override
  ConsumerState<ShoeDetailScreen> createState() => _ShoeDetailScreenState();
}

class _ShoeDetailScreenState extends ConsumerState<ShoeDetailScreen> {
  late int _currentShoeId;

  @override
  void initState() {
    super.initState();
    _currentShoeId = widget.shoeId;
  }

  int? get _currentIndex {
    final ids = widget.shoeIds;
    if (ids == null) return null;
    final i = ids.indexOf(_currentShoeId);
    return i == -1 ? null : i;
  }

  bool get _hasPrev {
    final i = _currentIndex;
    return i != null && i > 0;
  }

  bool get _hasNext {
    final i = _currentIndex;
    return i != null && widget.shoeIds != null && i < widget.shoeIds!.length - 1;
  }

  void _goPrev() {
    final i = _currentIndex;
    if (i != null && i > 0) {
      setState(() => _currentShoeId = widget.shoeIds![i - 1]);
    }
  }

  void _goNext() {
    final i = _currentIndex;
    if (i != null && widget.shoeIds != null && i < widget.shoeIds!.length - 1) {
      setState(() => _currentShoeId = widget.shoeIds![i + 1]);
    }
  }

  Future<void> _toggleFavorite(BuildContext context, Shoe shoe) async {
    final repository = ref.read(shoeRepositoryProvider);
    await repository.toggleFavorite(shoe.id!, !shoe.isFavorite);
    ref.invalidate(shoesProvider);
    ref.invalidate(shoeByIdProvider(shoe.id!));
  }

  Future<void> _toggleTopFive(
    BuildContext context,
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

  Future<void> _addPhoto(BuildContext context, Shoe shoe) async {
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

  Future<void> _changeStatus(BuildContext context, Shoe shoe) async {
    final result = await showModalBottomSheet<ShoeStatus>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ShoeStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                shoe.status == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: shoe.status == status
                    ? Theme.of(ctx).colorScheme.primary
                    : null,
              ),
              title: Text(status.label),
              onTap: () => Navigator.of(ctx).pop(status),
            );
          }).toList(),
        ),
      ),
    );
    if (result == null || result == shoe.status) return;

    await ref.read(shoeRepositoryProvider).updateStatus(shoe.id!, result);
    ref.invalidate(shoesProvider);
    ref.invalidate(shoeByIdProvider(_currentShoeId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ステータスを「${result.label}」に変更しました')),
      );
    }
  }

  void _shareShoe(Shoe shoe, Brand? brand) {
    final lines = <String>[
      '${brand?.name ?? ''} ${shoe.modelName}'.trim(),
      shoe.archiveNumber,
      '',
    ];
    if (shoe.size != null) lines.add('サイズ: ${shoe.size}');
    if (shoe.color != null) lines.add('カラー: ${shoe.color}');
    if (shoe.purchaseDate != null) {
      final d = shoe.purchaseDate!;
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      lines.add('購入日: ${d.year}/$mm/$dd');
    }
    if (shoe.purchasePrice != null) {
      lines.add('購入価格: ¥${shoe.purchasePrice}');
    }
    if (shoe.purchaseStore != null) lines.add('購入店: ${shoe.purchaseStore}');
    lines.add('');
    lines.add('#SoleMuseum');

    Share.share(lines.join('\n'), subject: shoe.modelName);
  }

  Future<void> _deleteShoe(BuildContext context, Shoe shoe) async {
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
      final photos = await ref
          .read(photoRepositoryProvider)
          .getPhotosByShoeId(shoe.id!);
      await ref.read(shoeRepositoryProvider).deleteShoe(shoe.id!);
      for (final photo in photos) {
        await ref
            .read(photoStorageServiceProvider)
            .deletePhotoFile(photo.filePath);
      }
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
  Widget build(BuildContext context) {
    final shoeAsync = ref.watch(shoeByIdProvider(_currentShoeId));
    final brandsAsync = ref.watch(brandsProvider);

    return shoeAsync.when(
      data: (shoe) {
        if (shoe == null) {
          return const Scaffold(
            body: Center(child: Text('スニーカーが見つかりません')),
          );
        }

        final brand = brandsAsync.maybeWhen(
          data: (brands) => _findBrand(brands, shoe.brandId),
          orElse: () => null,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(shoe.modelName),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: () => _addPhoto(context, shoe),
              ),
              IconButton(
                icon: Icon(shoe.isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () => _toggleFavorite(context, shoe),
              ),
              IconButton(
                tooltip: shoe.topOrder == null ? 'MY TOP 5に追加' : 'MY TOP 5から外す',
                icon: Icon(
                  shoe.topOrder == null
                      ? Icons.emoji_events_outlined
                      : Icons.emoji_events,
                ),
                onPressed: () => _toggleTopFive(context, shoe),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShoeFormScreen(shoe: shoe),
                    ),
                  );
                  ref.invalidate(shoeByIdProvider(_currentShoeId));
                },
              ),
              PopupMenuButton<_ShoeAction>(
                onSelected: (action) {
                  switch (action) {
                    case _ShoeAction.share:
                      _shareShoe(shoe, brand);
                    case _ShoeAction.changeStatus:
                      _changeStatus(context, shoe);
                    case _ShoeAction.delete:
                      _deleteShoe(context, shoe);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ShoeAction.share,
                    child: ListTile(
                      leading: Icon(Icons.ios_share_outlined),
                      title: Text('シェア'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _ShoeAction.changeStatus,
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz_outlined),
                      title: Text('ステータス変更'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _ShoeAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('削除'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: widget.shoeIds != null
              ? _ShoeNavBar(
                  currentIndex: _currentIndex!,
                  total: widget.shoeIds!.length,
                  hasPrev: _hasPrev,
                  hasNext: _hasNext,
                  onPrev: _goPrev,
                  onNext: _goNext,
                )
              : null,
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

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref, Photo photo) async {
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
      await ref.read(photoStorageServiceProvider).deletePhotoFile(photo.filePath);
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
    final wearLogsAsync = ref.watch(wearLogsByShoeIdProvider(shoe.id!));
    final wearCount = wearLogsAsync.maybeWhen(
      data: (logs) => logs.length,
      orElse: () => 0,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        mainPhotoAsync.when(
          data: (photo) => _MainPhoto(
            photo: photo,
            onDelete: photo == null ? null : () => _deletePhoto(context, ref, photo),
          ),
          loading: () => const _PhotoPlaceholder(label: '写真を読み込み中'),
          error: (_, __) => const _PhotoPlaceholder(label: '写真を読み込めませんでした'),
        ),
        const SizedBox(height: 16),
        Text(
          brand?.name ?? 'Unknown',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shoe.modelName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              shoe.archiveNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (wearCount > 0) ...[
              const SizedBox(width: 10),
              Icon(Icons.directions_walk, size: 13, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 2),
              Text(
                '$wearCount回着用',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        photosAsync.when(
          data: (photos) => _PhotoSections(
            photos: photos,
            shoeId: shoe.id!,
            onDeletePhoto: (photo) => _deletePhoto(context, ref, photo),
            onSetAsMain: (photo) async {
              if (photo.id == null) return;
              await ref.read(photoRepositoryProvider).setAsMainPhoto(
                    photo.id!,
                    shoe.id!,
                  );
              ref.invalidate(photosByShoeIdProvider(shoe.id!));
              ref.invalidate(mainPhotoProvider(shoe.id!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メイン写真に設定しました')),
                );
              }
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('写真一覧を読み込めませんでした'),
        ),
        const SizedBox(height: 24),
        WearHistorySection(shoeId: shoe.id!),
        const SizedBox(height: 32),
        Text('コレクション詳細', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _InfoTile(label: 'サイズ', value: shoe.size),
        _InfoTile(label: 'カラー', value: shoe.color),
        _InfoTile(label: '購入日', value: _formatDate(shoe.purchaseDate)),
        _InfoTile(label: '購入価格', value: shoe.purchasePrice == null ? null : '${shoe.purchasePrice}円'),
        _InfoTile(label: '購入店', value: shoe.purchaseStore),
        _InfoTile(label: 'メモ', value: shoe.memo),
        _InfoTile(label: 'ステータス', value: shoe.status.label),
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
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}/$mm/$dd';
  }
}

class _MainPhoto extends StatelessWidget {
  final Photo? photo;
  final VoidCallback? onDelete;

  const _MainPhoto({required this.photo, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo == null) {
      return const _PhotoPlaceholder(label: 'メイン写真を追加できます');
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotoViewerScreen(paths: [photo.filePath]),
          fullscreenDialog: true,
        ),
      ),
      onLongPress: onDelete,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(
              File(photo.filePath),
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(label: '写真ファイルが見つかりません'),
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

class _PhotoPlaceholder extends StatelessWidget {
  final String label;

  const _PhotoPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
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
  final int shoeId;
  final ValueChanged<Photo> onDeletePhoto;
  final ValueChanged<Photo> onSetAsMain;

  const _PhotoSections({
    required this.photos,
    required this.shoeId,
    required this.onDeletePhoto,
    required this.onSetAsMain,
  });

  @override
  Widget build(BuildContext context) {
    final galleryPhotos = photos.where((p) => p.photoType == PhotoType.gallery).toList();
    final boxPhotos = photos.where((p) => p.photoType == PhotoType.box).toList();

    if (galleryPhotos.isEmpty && boxPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (galleryPhotos.isNotEmpty) ...[
          _PhotoGrid(
            title: 'ギャラリー',
            photos: galleryPhotos,
            onDeletePhoto: onDeletePhoto,
            onSetAsMain: onSetAsMain,
          ),
          const SizedBox(height: 20),
        ],
        if (boxPhotos.isNotEmpty)
          _PhotoGrid(
            title: '箱写真',
            photos: boxPhotos,
            onDeletePhoto: onDeletePhoto,
            onSetAsMain: null,
          ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final String title;
  final List<Photo> photos;
  final ValueChanged<Photo> onDeletePhoto;
  final ValueChanged<Photo>? onSetAsMain;

  const _PhotoGrid({
    required this.title,
    required this.photos,
    required this.onDeletePhoto,
    required this.onSetAsMain,
  });

  void _showPhotoMenu(BuildContext context, Photo photo) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSetAsMain != null)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('メイン写真に設定'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onSetAsMain!(photo);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('削除'),
              onTap: () {
                Navigator.of(ctx).pop();
                onDeletePhoto(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final allPaths = photos.map((p) => p.filePath).toList();
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    paths: allPaths,
                    initialIndex: index,
                  ),
                  fullscreenDialog: true,
                ),
              ),
              onLongPress: () => _showPhotoMenu(context, photo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(photo.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    const Positioned(
                      right: 4,
                      bottom: 4,
                      child: Icon(Icons.more_vert, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
            Text('タップで拡大・長押しで削除'),
          ],
        ),
      ),
    );
  }
}

class _ShoeNavBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ShoeNavBar({
    required this.currentIndex,
    required this.total,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.chevron_left),
              onPressed: hasPrev ? onPrev : null,
            ),
            Text(
              '${currentIndex + 1} / $total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            IconButton.outlined(
              icon: const Icon(Icons.chevron_right),
              onPressed: hasNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ShoeAction { share, changeStatus, delete }

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value!),
    );
  }
}
