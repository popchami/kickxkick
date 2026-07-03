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
import '../providers/shelf_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/sticker_provider.dart';
import '../providers/wear_log_provider.dart';
import '../widgets/wear_history_section.dart';
import '../widgets/app_dialogs.dart';
import '../services/background_removal_service.dart';
import 'shoe_form_screen.dart';
import 'cutout_adjustment_screen.dart';

class ShoeDetailScreen extends ConsumerWidget {
  final int shoeId;

  const ShoeDetailScreen({super.key, required this.shoeId});

  Future<void> _toggleTopFive(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final shouldSelect = shoe.topOrder == null;
    final updated = await ref.read(shoeRepositoryProvider).setTopFive(
          shoe.id!,
          shouldSelect,
        );

    if (updated) {
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider(shoe.id!));
    }

    if (!updated && context.mounted) {
      await showAppMessage(context, title: 'MY TOP 5は5足までです');
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
    PhotoType photoType,
  ) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    if (!context.mounted) return;
    final result = await Navigator.of(context).push<CutoutResult>(
      MaterialPageRoute(
        builder: (_) => CutoutAdjustmentScreen(
          sourcePath: pickedFile.path,
          shoeId: shoe.id!,
        ),
      ),
    );
    if (result == null) return;

    try {
      final filePath = await ref.read(photoStorageServiceProvider).savePhoto(
            sourceFile: File(pickedFile.path),
            shoeId: shoe.id!,
            photoType: photoType,
          );
      final previousPhotos = await ref.read(photoRepositoryProvider).replacePhoto(
            Photo.create(
              shoeId: shoe.id!,
              photoType: photoType,
              filePath: filePath,
              cutoutPath: result.cutoutPath,
              cutoutMaskPath: result.maskPath,
              cutoutThreshold: result.threshold,
              cutoutEngine: result.engine,
              cutoutSmoothing: result.smoothing,
              cutoutAntialiasing: result.antialiasing,
              cropOffsetXFrac: result.offsetXFrac,
              cropOffsetYFrac: result.offsetYFrac,
              cropWidthFrac: result.widthFrac,
              cropHeightFrac: result.heightFrac,
            ),
          );
      final storage = ref.read(photoStorageServiceProvider);
      for (final previousPhoto in previousPhotos) {
        try {
          await storage.deletePhotoFile(previousPhoto.filePath);
        } catch (_) {
          // Database replacement already succeeded; cleanup is best effort.
        }
      }
      ref.invalidate(photosByShoeIdProvider(shoe.id!));
      ref.invalidate(mainPhotoProvider(shoe.id!));
    } catch (_) {
      if (context.mounted) {
        await showAppMessage(context, title: '写真を更新できませんでした');
      }
    }
  }

  Future<void> _selectMainPhoto(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
    List<Photo> photos,
  ) async {
    final candidates = photos.where((photo) => photo.photoType != PhotoType.main).toList();
    if (candidates.isEmpty) {
      await showAppMessage(context, title: '先に他の写真を登録してください');
      return;
    }
    final selected = await showModalBottomSheet<Photo>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: candidates.length,
          itemBuilder: (context, index) => InkWell(
            onTap: () => Navigator.pop(context, candidates[index]),
            child: Image.file(File(candidates[index].filePath), fit: BoxFit.cover),
          ),
        ),
      ),
    );
    if (selected == null) return;
    await ref.read(photoRepositoryProvider).setMainPhoto(selected);
    ref.invalidate(photosByShoeIdProvider(shoe.id!));
    ref.invalidate(mainPhotoProvider(shoe.id!));
  }

  Future<void> _addToShelf(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final shelfId = await ref.read(defaultShelfIdProvider.future);
    try {
      final result = await ref
          .read(shelfRepositoryProvider)
          .addShoeToShelf(shelfId, shoe.id!);
      if (!context.mounted) return;
      if (result == null) {
        await showAppMessage(context, title: '棚がいっぱいです', message: '棚には25足まで置けます。');
        return;
      }
      ref.invalidate(shelfItemsProvider(shelfId));
    } catch (_) {
      if (context.mounted) {
        await showAppMessage(context, title: 'この靴はすでに棚にあります');
      }
    }
  }

  Future<void> _deleteShoe(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スニーカーを削除しますか？'),
        content: Text(
          '${shoe.displayTitle?.isNotEmpty == true ? shoe.displayTitle! : shoe.modelName}を削除します。'
          '写真と着用履歴も削除されます。この操作は取り消せません。',
        ),
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

    final deletedCount = await ref.read(shoeRepositoryProvider).deleteShoe(shoe.id!);
    ref.invalidate(shoesProvider);
    ref.invalidate(shoeByIdProvider(shoe.id!));
    ref.invalidate(photosByShoeIdProvider(shoe.id!));
    ref.invalidate(mainPhotoProvider(shoe.id!));
    ref.invalidate(wearLogsByShoeIdProvider(shoe.id!));
    ref.invalidate(recentWearLogsProvider);

    if (context.mounted) {
      if (deletedCount > 0) {
        Navigator.of(context).pop(true);
      } else {
        await showAppMessage(context, title: '削除できませんでした');
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
            title: Text(
              shoe.displayTitle?.isNotEmpty == true
                  ? shoe.displayTitle!
                  : shoe.modelName,
            ),
            actions: [
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteShoe(context, ref, shoe);
                  } else if (value == 'add_to_shelf') {
                    _addToShelf(context, ref, shoe);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'add_to_shelf',
                    child: ListTile(
                      leading: Icon(Icons.grid_view_outlined),
                      title: Text('棚に追加'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('削除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: brandsAsync.when(
            data: (brands) => _DetailBody(
              shoe: shoe,
              brand: _findBrand(brands, shoe.brandId),
              onPickPhoto: (type) => _pickPhoto(context, ref, shoe, type),
              onSelectMainPhoto: (photos) =>
                  _selectMainPhoto(context, ref, shoe, photos),
              onToggleTopFive: () => _toggleTopFive(context, ref, shoe),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _DetailBody(
              shoe: shoe,
              brand: null,
              onPickPhoto: (type) => _pickPhoto(context, ref, shoe, type),
              onSelectMainPhoto: (photos) =>
                  _selectMainPhoto(context, ref, shoe, photos),
              onToggleTopFive: () => _toggleTopFive(context, ref, shoe),
            ),
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
  final ValueChanged<PhotoType> onPickPhoto;
  final ValueChanged<List<Photo>> onSelectMainPhoto;
  final VoidCallback onToggleTopFive;

  const _DetailBody({
    required this.shoe,
    required this.brand,
    required this.onPickPhoto,
    required this.onSelectMainPhoto,
    required this.onToggleTopFive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
    final photosAsync = ref.watch(photosByShoeIdProvider(shoe.id!));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        mainPhotoAsync.when(
          data: (photo) => _MainPhotoSection(
            photo: photo,
            shoeId: shoe.id!,
          ),
          loading: () => const _PhotoPlaceholder(label: '写真を読み込み中'),
          error: (_, __) => const _PhotoPlaceholder(label: '写真を読み込めませんでした'),
        ),
        const SizedBox(height: 16),
        photosAsync.when(
          data: (photos) => _PhotoGallery(
            photos: photos,
            onPickPhoto: onPickPhoto,
            onSelectMain: () => onSelectMainPhoto(photos),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('写真一覧を読み込めませんでした'),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(shoe.topOrder == null ? 'MY TOP 5に追加' : 'MY TOP 5登録済み'),
            subtitle: Text(
              shoe.topOrder == null ? 'Home上部に表示する5足へ登録します' : 'No. ${shoe.topOrder}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onToggleTopFive,
          ),
        ),
        const SizedBox(height: 24),
        WearHistorySection(shoeId: shoe.id!),
        const SizedBox(height: 24),
        _InfoTile(label: 'ブランド', value: brand?.name ?? 'Unknown'),
        _InfoTile(label: 'アーカイブ番号', value: shoe.archiveNumber),
        _InfoTile(label: 'Display Title', value: shoe.displayTitle),
        _InfoTile(label: 'モデル名', value: shoe.modelName),
        _InfoTile(label: 'ステッカーテキスト', value: shoe.stickerText),
        _InfoTile(label: '状態', value: shoe.statusLabel),
        _InfoTile(label: 'サイズ', value: shoe.size),
        _InfoTile(label: 'カラー', value: shoe.color),
        _InfoTile(label: '購入日', value: _formatDate(shoe.purchaseDate)),
        _InfoTile(
          label: '購入価格',
          value: shoe.purchasePrice == null ? null : '${shoe.purchasePrice}円',
        ),
        _InfoTile(label: '購入店', value: shoe.purchaseStore),
        _InfoTile(label: 'メモ', value: shoe.memo),
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

class _MainPhotoSection extends ConsumerStatefulWidget {
  final Photo? photo;
  final int shoeId;

  const _MainPhotoSection({required this.photo, required this.shoeId});

  @override
  ConsumerState<_MainPhotoSection> createState() => _MainPhotoSectionState();
}

class _MainPhotoSectionState extends ConsumerState<_MainPhotoSection> {
  bool _isRegenerating = false;
  bool _isSlow = false;

  Future<void> _regenerate() async {
    final photo = widget.photo;
    if (photo == null || photo.cutoutPath == null) return;

    final hasMask = photo.cutoutMaskPath != null &&
        await File(photo.cutoutMaskPath!).exists();

    setState(() {
      _isRegenerating = true;
      _isSlow = !hasMask;
    });

    try {
      final service = BackgroundRemovalService();
      final CutoutResult result;

      if (hasMask) {
        result = await service.regenerateFromMask(
          sourcePath: photo.filePath,
          maskPath: photo.cutoutMaskPath!,
          shoeId: widget.shoeId,
          threshold: photo.cutoutThreshold,
          smoothing: photo.cutoutSmoothing,
          antialiasing: photo.cutoutAntialiasing,
        );
      } else {
        result = await service.removeEdgeBackground(
          photo.filePath,
          widget.shoeId,
          threshold: photo.cutoutThreshold,
          smoothing: photo.cutoutSmoothing,
          antialiasing: photo.cutoutAntialiasing,
        );
      }

      await ref.read(photoRepositoryProvider).updatePhoto(
        photo.copyWith(
          cutoutPath: result.cutoutPath,
          cutoutMaskPath: result.maskPath ?? photo.cutoutMaskPath,
          cutoutThreshold: result.threshold,
          cutoutEngine: result.engine,
          cutoutSmoothing: result.smoothing,
          cutoutAntialiasing: result.antialiasing,
          cropOffsetXFrac: result.offsetXFrac,
          cropOffsetYFrac: result.offsetYFrac,
          cropWidthFrac: result.widthFrac,
          cropHeightFrac: result.heightFrac,
        ),
      );

      await ref.read(stickerRepositoryProvider).updateStickerCutout(
        shoeId: widget.shoeId,
        sourcePath: photo.filePath,
        stickerPath: result.cutoutPath,
        cropOffsetXFrac: result.offsetXFrac,
        cropOffsetYFrac: result.offsetYFrac,
        cropWidthFrac: result.widthFrac,
        cropHeightFrac: result.heightFrac,
      );

      ref.invalidate(mainPhotoProvider(widget.shoeId));
      ref.invalidate(photosByShoeIdProvider(widget.shoeId));
      ref.invalidate(stickersProvider);
    } catch (_) {
      if (mounted) {
        await showAppMessage(context, title: '再生成に失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
          _isSlow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;

    return Column(
      children: [
        if (photo == null)
          Ink(
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
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(
              File(photo.cutoutPath ?? photo.filePath),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(
                label: '写真ファイルが見つかりません',
              ),
            ),
          ),
        if (photo != null && photo.cutoutPath != null) ...[
          const SizedBox(height: 8),
          if (_isRegenerating)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                if (_isSlow) ...[
                  const SizedBox(width: 8),
                  Text(
                    '処理中...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            )
          else
            TextButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('切り抜きを再生成'),
            ),
        ],
      ],
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.photos,
    required this.onPickPhoto,
    required this.onSelectMain,
  });

  final List<Photo> photos;
  final ValueChanged<PhotoType> onPickPhoto;
  final VoidCallback onSelectMain;

  static const slots = <(PhotoType, String)>[
    (PhotoType.right, '右側'),
    (PhotoType.left, '左側'),
    (PhotoType.top, '真上'),
    (PhotoType.rear, '後'),
    (PhotoType.sole, '底'),
    (PhotoType.box, '箱'),
    (PhotoType.wear1, '着用1'),
    (PhotoType.wear2, '着用2'),
    (PhotoType.wear3, '着用3'),
  ];

  @override
  Widget build(BuildContext context) {
    final byType = {for (final photo in photos) photo.photoType: photo};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('写真', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: onSelectMain,
              icon: const Icon(Icons.star_outline),
              label: const Text('メインを選択'),
            ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final photo = byType[slot.$1];
            return InkWell(
              onTap: () => onPickPhoto(slot.$1),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  color: photo == null
                      ? Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: photo == null
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.45),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: photo == null
                          ? Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 22,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.65),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.file(
                                File(photo.cutoutPath ?? photo.filePath),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        slot.$2,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: photo == null
                                  ? Theme.of(context).colorScheme.outline
                                  : null,
                            ),
                      ),
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
      child: Center(child: Text(label)),
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
