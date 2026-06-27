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
import '../providers/wear_log_provider.dart';
import '../widgets/wear_history_section.dart';
import '../widgets/app_dialogs.dart';
import 'shoe_form_screen.dart';

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

  Future<void> _replaceMainPhoto(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
  ) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    try {
      final filePath = await ref.read(photoStorageServiceProvider).savePhoto(
            sourceFile: File(pickedFile.path),
            shoeId: shoe.id!,
            photoType: PhotoType.main,
          );
      final previousPhotos = await ref.read(photoRepositoryProvider).replaceMainPhoto(
            Photo.create(
              shoeId: shoe.id!,
              photoType: PhotoType.main,
              filePath: filePath,
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteShoe(context, ref, shoe);
                  }
                },
                itemBuilder: (_) => const [
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
              onReplaceMainPhoto: () => _replaceMainPhoto(context, ref, shoe),
              onToggleTopFive: () => _toggleTopFive(context, ref, shoe),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _DetailBody(
              shoe: shoe,
              brand: null,
              onReplaceMainPhoto: () => _replaceMainPhoto(context, ref, shoe),
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
  final VoidCallback onReplaceMainPhoto;
  final VoidCallback onToggleTopFive;

  const _DetailBody({
    required this.shoe,
    required this.brand,
    required this.onReplaceMainPhoto,
    required this.onToggleTopFive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        mainPhotoAsync.when(
          data: (photo) => _MainPhoto(
            photo: photo,
            onAddOrChange: onReplaceMainPhoto,
          ),
          loading: () => const _PhotoPlaceholder(label: '写真を読み込み中'),
          error: (_, __) => const _PhotoPlaceholder(label: '写真を読み込めませんでした'),
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

class _MainPhoto extends StatelessWidget {
  final Photo? photo;
  final VoidCallback onAddOrChange;

  const _MainPhoto({required this.photo, required this.onAddOrChange});

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    if (currentPhoto == null) {
      return InkWell(
        onTap: onAddOrChange,
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

    return Stack(
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
            onPressed: onAddOrChange,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('変更'),
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
