import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/shoe.dart';
import '../models/sticker_asset.dart';
import '../models/brand.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/sticker_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/sticker_repository.dart';
import '../services/background_removal_service.dart';
import '../widgets/empty_state.dart';
import 'cutout_adjustment_screen.dart';

class StickerScreen extends ConsumerStatefulWidget {
  const StickerScreen({super.key});

  @override
  ConsumerState<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends ConsumerState<StickerScreen> {
  int _revision = 0;
  final _boardKey = GlobalKey<_StickerBoardState>();
  final _searchController = TextEditingController();
  String _searchText = '';
  int? _selectedBrandId;
  String? _selectedStatus;
  String? _selectedColor;
  bool _editMode = false;
  int? _pasteStickerId;
  StickerAsset? _selectedSticker;
  StickerBoardItem? _selectedBoardItem;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickersAsync = ref.watch(stickersProvider);
    final shoes = ref.watch(shoesProvider).value ?? const <Shoe>[];
    final brands = ref.watch(brandsProvider).value ?? const [];
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };
    final colors = shoes
        .expand((shoe) => (shoe.color ?? '').split(','))
        .map((color) => color.trim())
        .where((color) => color.isNotEmpty)
        .toSet()
        .toList();
    final activeFilterCount =
        [_selectedBrandId, _selectedStatus, _selectedColor]
            .where((value) => value != null)
            .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker'),
        actions: [
          IconButton(
            onPressed: () => _boardKey.currentState?.exportBoard(),
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'ボードを共有',
          ),
          PopupMenuButton<_StickerBoardCommand>(
            tooltip: 'ステッカーメニュー',
            icon: const Icon(Icons.menu),
            onSelected: (command) async {
              if (command == _StickerBoardCommand.toggleEdit) {
                setState(() {
                  _editMode = !_editMode;
                  if (!_editMode) {
                    _selectedSticker = null;
                    _selectedBoardItem = null;
                  }
                });
              } else {
                final asset = _selectedSticker;
                final item = _selectedBoardItem;
                if (asset == null || item == null) return;
                final action = switch (command) {
                  _StickerBoardCommand.cutout => _StickerEditAction.cutout,
                  _ => null,
                };
                if (action != null) {
                  await _editSticker(asset, shoes, action: action);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _StickerBoardCommand.toggleEdit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_editMode ? Icons.visibility : Icons.edit),
                  title: Text(_editMode ? '閲覧モードにする' : 'ステッカー編集'),
                  subtitle: Text(
                    _editMode ? '移動操作を無効にします' : '移動・貼り付け・削除を行います',
                  ),
                ),
              ),
              if (_editMode) const PopupMenuDivider(),
              if (_editMode)
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    _selectedSticker == null ? 'ステッカー未選択' : '選択中のステッカー',
                  ),
                ),
              if (_editMode && _selectedSticker != null) ...[
                const PopupMenuItem(
                  value: _StickerBoardCommand.cutout,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.auto_fix_high),
                    title: Text('切り抜きを再編集'),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            onPressed: shoes.isEmpty ? null : () => _createSticker(shoes),
            icon: const Icon(Icons.add),
            tooltip: 'ステッカーを作る',
          ),
        ],
      ),
      body: stickersAsync.when(
        data: (stickers) {
          final query = _searchText.trim().toLowerCase();
          final matchingShoeIds = shoes
              .where((shoe) {
                final brandName = brandNames[shoe.brandId] ?? '';
                final matchesQuery = query.isEmpty ||
                    shoe.modelName.toLowerCase().contains(query) ||
                    brandName.toLowerCase().contains(query) ||
                    (shoe.displayTitle?.toLowerCase().contains(query) ?? false) ||
                    (shoe.stickerText?.toLowerCase().contains(query) ?? false);
                final matchesBrand =
                    _selectedBrandId == null || shoe.brandId == _selectedBrandId;
                final matchesStatus =
                    _selectedStatus == null || shoe.status == _selectedStatus;
                final matchesColor = _selectedColor == null ||
                    (shoe.color ?? '')
                        .split(',')
                        .map((color) => color.trim())
                        .contains(_selectedColor);
                return matchesQuery && matchesBrand && matchesStatus && matchesColor;
              })
              .map((shoe) => shoe.id)
              .toSet();
          final visibleStickers = stickers
              .where((sticker) => matchingShoeIds.contains(sticker.shoeId))
              .toList();
          if (stickers.isEmpty) {
            return EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'まだステッカーがありません',
              description: '写真を登録したスニーカーからステッカーを作れます。',
              actionLabel: 'ステッカーを作る',
              onAction: shoes.isEmpty ? null : () => _createSticker(shoes),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'モデル名で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchText.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                            },
                          ),
                        Badge(
                          isLabelVisible: activeFilterCount > 0,
                          label: Text('$activeFilterCount'),
                          child: IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: '絞り込み',
                            onPressed: () =>
                                _showFilters(brands: brands, colors: colors),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              Expanded(
                child: visibleStickers.isEmpty
                    ? const Center(child: Text('該当するステッカーがありません'))
                    : FutureBuilder<_BoardData>(
                        key: ValueKey((_revision, _searchText)),
                        future: _loadBoard(stickers),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final data = snapshot.data!;
                          return _StickerBoard(
                            key: _boardKey,
                            stickers: visibleStickers,
                            items: data.items,
                            editMode: _editMode,
                            selectedItemId: _selectedBoardItem?.id,
                            onPaste: (position) => _pasteStickerAt(
                              data.boardId,
                              stickers,
                              position,
                            ),
                            onChanged: (item) =>
                                ref.read(stickerRepositoryProvider).updateBoardItem(item),
                            onEdit: (asset, item) => setState(() {
                              _selectedSticker = asset;
                              _selectedBoardItem = item;
                            }),
                            onDesign: (asset, item) =>
                                _editSticker(asset, shoes, action: _StickerEditAction.design),
                            onToolAction: (asset, item, action) =>
                                _handleStickerTool(asset, item, action),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('ステッカーを読み込めませんでした')),
      ),
    );
  }

  Future<void> _showFilters({
    required List<Brand> brands,
    required List<String> colors,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('絞り込み', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedBrandId = null;
                        _selectedStatus = null;
                        _selectedColor = null;
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('すべて解除'),
                  ),
                ],
              ),
              _StickerFilterGroup(
                label: '状態',
                children: [
                  _filterChip(sheetContext, 'すべて', _selectedStatus == null,
                      () => _selectedStatus = null),
                  _filterChip(sheetContext, '新品', _selectedStatus == Shoe.statusNew,
                      () => _selectedStatus = Shoe.statusNew),
                  _filterChip(sheetContext, '着用済み', _selectedStatus == Shoe.statusWorn,
                      () => _selectedStatus = Shoe.statusWorn),
                  _filterChip(sheetContext, '手放した', _selectedStatus == Shoe.statusParted,
                      () => _selectedStatus = Shoe.statusParted),
                ],
              ),
              _StickerFilterGroup(
                label: 'ブランド',
                children: [
                  _filterChip(sheetContext, 'すべて', _selectedBrandId == null,
                      () => _selectedBrandId = null),
                  ...brands.map((brand) => _filterChip(
                        sheetContext,
                        brand.name,
                        _selectedBrandId == brand.id,
                        () => _selectedBrandId = brand.id,
                      )),
                ],
              ),
              if (colors.isNotEmpty)
                _StickerFilterGroup(
                  label: 'カラー',
                  children: [
                    _filterChip(sheetContext, 'すべて', _selectedColor == null,
                        () => _selectedColor = null),
                    ...colors.map((color) => _filterChip(
                          sheetContext,
                          color,
                          _selectedColor == color,
                          () => _selectedColor = color,
                        )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext sheetContext,
    String label,
    bool selected,
    VoidCallback update,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(update);
        Navigator.pop(sheetContext);
      },
    );
  }

  Future<_BoardData> _loadBoard(List<StickerAsset> stickers) async {
    final repository = ref.read(stickerRepositoryProvider);
    final boardId = await repository.ensureDefaultBoard();
    return _BoardData(boardId, await repository.getBoardItems(boardId));
  }

  Future<void> _pasteStickerAt(
    int boardId,
    List<StickerAsset> stickers,
    Offset position,
  ) async {
    if (!_editMode || stickers.isEmpty) return;
    if (!await _checkBoardCapacity(boardId)) return;
    StickerAsset? selected;
    for (final asset in stickers) {
      if (asset.id == _pasteStickerId) {
        selected = asset;
        break;
      }
    }
    if (selected == null || !mounted) return;
    await ref.read(stickerRepositoryProvider).pasteToBoard(
          boardId,
          selected.id,
          x: position.dx,
          y: position.dy,
        );
    if (mounted) setState(() => _revision++);
  }

  Future<void> _createSticker(List<Shoe> shoes) async {
    final shoe = await showDialog<Shoe>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スニーカーを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shoes.length,
            itemBuilder: (context, index) {
              final shoe = shoes[index];
              return ListTile(
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
    if (shoe == null || !mounted) return;
    final photo = await ref.read(photoRepositoryProvider).getMainPhoto(shoe.id!);
    if (!mounted) return;
    if (photo == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('メイン写真が必要です'),
          content: const Text('Detail画面で写真を追加してから作成してください。'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingOpen = true;
    try {
      var cutoutPath = photo.cutoutPath;
      if (cutoutPath == null || !await File(cutoutPath).exists()) {
        cutoutPath = await BackgroundRemovalService()
            .removeEdgeBackground(photo.filePath, shoe.id!);
        await ref.read(photoRepositoryProvider).updatePhoto(
              photo.copyWith(cutoutPath: cutoutPath),
            );
        ref.invalidate(mainPhotoProvider(shoe.id!));
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingOpen = false;
      }
      if (!mounted) return;
      final design = await _showStickerDesigner(shoe, cutoutPath);
      if (design == null || !mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingOpen = true;
      final repository = ref.read(stickerRepositoryProvider);
      final stickerId = await repository.saveSticker(
        shoeId: shoe.id!,
        sourcePath: photo.filePath,
        stickerPath: cutoutPath,
        stickerText: design.text,
        textColor: design.textColor,
        innerBorderColor: design.innerBorderColor,
        outerBorderColor: design.outerBorderColor,
        shadowEnabled: design.shadowEnabled,
        textScale: design.textScale,
        textX: design.textX,
        textY: design.textY,
      );
      final boardId = await repository.ensureDefaultBoard();
      final count = await repository.getBoardItemCount(boardId);
      final isPremium =
          await ref.read(settingsRepositoryProvider).getValue('is_premium') == 'true';
      final limit = isPremium
          ? StickerRepository.premiumBoardItemLimit
          : StickerRepository.freeBoardItemLimit;
      if (count < limit) {
        await repository.addToBoard(boardId, stickerId);
      }
      ref.invalidate(stickersProvider);
      setState(() => _revision++);
    } catch (_) {
      if (mounted) {
        if (loadingOpen) Navigator.of(context, rootNavigator: true).pop();
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ステッカーを作成できませんでした'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
          ),
        );
      }
      return;
    }
    if (mounted && loadingOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<_StickerDesign?> _showStickerDesigner(
    Shoe shoe,
    String cutoutPath, [
    StickerAsset? existing,
  ]) async {
    var text = existing?.stickerText?.trim() ?? shoe.stickerText?.trim() ?? '';
    var textColor = existing?.textColor ?? 0xFFFF6A00;
    var innerColor = existing?.innerBorderColor ?? 0xFFFFFFFF;
    var outerColor = existing?.outerBorderColor ?? 0xFFFF6A00;
    var shadow = existing?.shadowEnabled ?? true;
    var textScale = existing?.textScale ?? .75;
    var textX = existing?.textX ?? .5;
    var textY = existing?.textY ?? .55;
    const colors = <int>[
      0xFFFFFFFF, 0xFF111111, 0xFFFF6A00, 0xFFFFC400,
      0xFFE53935, 0xFFEC407A, 0xFF7E57C2, 0xFF1E88E5,
      0xFF00ACC1, 0xFF43A047,
    ];
    return showDialog<_StickerDesign>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          final preview = StickerAsset(
            id: 0,
            shoeId: shoe.id!,
            sourcePath: cutoutPath,
            stickerPath: cutoutPath,
            stickerText: text,
            textColor: textColor,
            innerBorderColor: innerColor,
            outerBorderColor: outerColor,
            shadowEnabled: shadow,
            textScale: textScale,
            textX: textX,
            textY: textY,
          );
          Widget palette(String label, int selected, ValueChanged<int> set) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((value) {
                    final active = value == selected;
                    return InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => setLocalState(() => set(value)),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: active ? 3 : 1,
                          ),
                        ),
                        child: active
                            ? Icon(
                                Icons.check,
                                size: 17,
                                color: value == 0xFFFFFFFF ? Colors.black : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          return AlertDialog(
            title: const Text('ステッカーデザイン'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: text,
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: 'ステッカーテキスト',
                        helperText: '靴詳細の文字を初期値として使用します',
                      ),
                      onChanged: (value) => setLocalState(() => text = value),
                    ),
                    Container(
                      height: 180,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E7D3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _StickerArtwork(
                        asset: preview,
                        size: 160,
                        onTextPositionChanged: (position) => setLocalState(() {
                          textX = position.dx;
                          textY = position.dy;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 64, child: Text('文字サイズ')),
                        Expanded(
                          child: Slider(
                            value: textScale,
                            min: .6,
                            max: 1.6,
                            divisions: 20,
                            onChanged: (value) => setLocalState(() => textScale = value),
                          ),
                        ),
                      ],
                    ),
                    palette('文字色', textColor, (value) => textColor = value),
                    palette('内フチ（標準：白）', innerColor, (value) => innerColor = value),
                    palette('外フチ（標準：オレンジ）', outerColor, (value) => outerColor = value),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Shadow'),
                      value: shadow,
                      onChanged: (value) => setLocalState(() => shadow = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _StickerDesign(
                    text: text.trim().isEmpty ? null : text.trim(),
                    textColor: textColor,
                    innerBorderColor: innerColor,
                    outerBorderColor: outerColor,
                    shadowEnabled: shadow,
                    textScale: textScale,
                    textX: textX,
                    textY: textY,
                  ),
                ),
                child: const Text('作成'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editSticker(
    StickerAsset asset,
    List<Shoe> shoes, {
    required _StickerEditAction action,
  }) async {
    Shoe? shoe;
    for (final value in shoes) {
      if (value.id == asset.shoeId) {
        shoe = value;
        break;
      }
    }
    if (shoe == null) return;
    var stickerPath = asset.stickerPath;
    var design = _StickerDesign(
      text: asset.stickerText,
      textColor: asset.textColor,
      innerBorderColor: asset.innerBorderColor,
      outerBorderColor: asset.outerBorderColor,
      shadowEnabled: asset.shadowEnabled,
      textScale: asset.textScale,
      textX: asset.textX,
      textY: asset.textY,
    );
    if (action == _StickerEditAction.cutout) {
      final editedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CutoutAdjustmentScreen(
            sourcePath: asset.sourcePath,
            shoeId: asset.shoeId,
            initialCutoutPath: asset.stickerPath,
          ),
        ),
      );
      if (editedPath == null || !mounted) return;
      stickerPath = editedPath;
      final photo = await ref.read(photoRepositoryProvider).getMainPhoto(asset.shoeId);
      if (photo != null) {
        await ref.read(photoRepositoryProvider).updatePhoto(
              photo.copyWith(cutoutPath: editedPath),
            );
        ref.invalidate(mainPhotoProvider(asset.shoeId));
      }
    } else {
      final updated = await _showStickerDesigner(shoe, asset.stickerPath, asset);
      if (updated == null || !mounted) return;
      design = updated;
    }

    await ref.read(stickerRepositoryProvider).saveSticker(
          shoeId: asset.shoeId,
          sourcePath: asset.sourcePath,
          stickerPath: stickerPath,
          stickerText: design.text,
          textColor: design.textColor,
          innerBorderColor: design.innerBorderColor,
          outerBorderColor: design.outerBorderColor,
          shadowEnabled: design.shadowEnabled,
          textScale: design.textScale,
          textX: design.textX,
          textY: design.textY,
        );
    ref.invalidate(stickersProvider);
    if (mounted) setState(() => _revision++);
  }

  Future<void> _handleStickerTool(
    StickerAsset asset,
    StickerBoardItem item,
    _StickerToolAction action,
  ) async {
    final repository = ref.read(stickerRepositoryProvider);
    switch (action) {
      case _StickerToolAction.paste:
        setState(() => _pasteStickerId = asset.id);
      case _StickerToolAction.duplicate:
        if (!await _checkBoardCapacity(item.boardId)) return;
        await repository.duplicateBoardItem(item);
        if (mounted) setState(() => _revision++);
      case _StickerToolAction.delete:
        await repository.deleteBoardItem(item.id);
        if (mounted) {
          setState(() {
            _selectedSticker = null;
            _selectedBoardItem = null;
            _revision++;
          });
        }
      case _StickerToolAction.zoomIn:
        await repository.updateBoardItem(
          item.copyWith(scale: (item.scale + .1).clamp(.75, 1.5)),
        );
        if (mounted) setState(() => _revision++);
      case _StickerToolAction.zoomOut:
        await repository.updateBoardItem(
          item.copyWith(scale: (item.scale - .1).clamp(.75, 1.5)),
        );
        if (mounted) setState(() => _revision++);
      case _StickerToolAction.bringFront:
        await repository.bringToFront(item);
        if (mounted) setState(() => _revision++);
    }
  }

  Future<bool> _checkBoardCapacity(int boardId) async {
    final isPremium =
        await ref.read(settingsRepositoryProvider).getValue('is_premium') == 'true';
    final limit = isPremium
        ? StickerRepository.premiumBoardItemLimit
        : StickerRepository.freeBoardItemLimit;
    final count = await ref.read(stickerRepositoryProvider).getBoardItemCount(boardId);
    if (count < limit) return true;
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ボードの上限です'),
        content: Text(
          isPremium
              ? 'Premiumでは1ボード30枚まで貼り付けできます。'
              : '無料版では1ボード10枚までです。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    return false;
  }
}

enum _StickerBoardCommand { toggleEdit, cutout }

enum _StickerEditAction { cutout, design }

enum _StickerToolAction { paste, duplicate, delete, zoomIn, zoomOut, bringFront }

class _StickerDesign {
  const _StickerDesign({
    required this.text,
    required this.textColor,
    required this.innerBorderColor,
    required this.outerBorderColor,
    required this.shadowEnabled,
    required this.textScale,
    required this.textX,
    required this.textY,
  });

  final String? text;
  final int textColor;
  final int innerBorderColor;
  final int outerBorderColor;
  final bool shadowEnabled;
  final double textScale;
  final double textX;
  final double textY;
}

class _StickerFilterGroup extends StatelessWidget {
  const _StickerFilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _BoardData {
  const _BoardData(this.boardId, this.items);
  final int boardId;
  final List<StickerBoardItem> items;
}

class _StickerBoard extends StatefulWidget {
  const _StickerBoard({
    super.key,
    required this.stickers,
    required this.items,
    required this.editMode,
    required this.selectedItemId,
    required this.onPaste,
    required this.onChanged,
    required this.onEdit,
    required this.onDesign,
    required this.onToolAction,
  });
  final List<StickerAsset> stickers;
  final List<StickerBoardItem> items;
  final bool editMode;
  final int? selectedItemId;
  final ValueChanged<Offset> onPaste;
  final ValueChanged<StickerBoardItem> onChanged;
  final void Function(StickerAsset asset, StickerBoardItem item) onEdit;
  final void Function(StickerAsset asset, StickerBoardItem item) onDesign;
  final void Function(StickerAsset, StickerBoardItem, _StickerToolAction) onToolAction;

  @override
  State<_StickerBoard> createState() => _StickerBoardState();
}

class _StickerBoardState extends State<_StickerBoard> {
  late List<StickerBoardItem> _items;
  int? _selectedTextId;
  double _startScale = 1;
  double _startRotation = 0;
  Offset? _rotationCenter;
  double _handleStartAngle = 0;
  double _handleStartRotation = 0;
  final GlobalKey _boardKey = GlobalKey();
  final _textController = TextEditingController();

  int? get _textPanelItemId => _selectedTextId ?? widget.selectedItemId;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant _StickerBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = [...widget.items];
    }
    if (oldWidget.selectedItemId != widget.selectedItemId &&
        widget.selectedItemId != null) {
      final item = _items.where((i) => i.id == widget.selectedItemId).firstOrNull;
      if (item != null) {
        _textController.text = item.textContent;
        if (_selectedTextId != null) setState(() => _selectedTextId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = {for (final value in widget.stickers) value.id: value};
    StickerBoardItem? selectedItem;
    for (final item in _items) {
      if (item.id == widget.selectedItemId) {
        selectedItem = item;
        break;
      }
    }
    return Column(
      children: [
        if (_textPanelItemId != null) _buildTextEditPanel(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: RepaintBoundary(
                key: _boardKey,
                child: SizedBox.expand(
                  child: LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: widget.editMode
                          ? (details) => widget.onPaste(Offset(
                                (details.localPosition.dx / constraints.maxWidth)
                                    .clamp(0, .78),
                                (details.localPosition.dy / constraints.maxHeight)
                                    .clamp(0, .82),
                              ))
                          : null,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E7D3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            ..._items.map((item) {
                              final asset = assets[item.stickerId];
                              if (asset == null) return const SizedBox.shrink();
                              return Positioned(
                                left: item.x * constraints.maxWidth,
                                top: item.y * constraints.maxHeight,
                                child: GestureDetector(
                                  onTap: widget.editMode
                                      ? () {
                                          setState(() => _selectedTextId = null);
                                          widget.onEdit(asset, item);
                                        }
                                      : null,
                                  onLongPress: widget.editMode
                                      ? () => widget.onDesign(asset, item)
                                      : null,
                                  onScaleStart: (_) {
                                    _startScale = item.scale;
                                    _startRotation = item.rotation;
                                  },
                                  onScaleUpdate: (details) {
                                    final index = _items
                                        .indexWhere((value) => value.id == item.id);
                                    setState(() {
                                      _items[index] = item.copyWith(
                                        x: (item.x +
                                                details.focalPointDelta.dx /
                                                    constraints.maxWidth)
                                            .clamp(0, .78),
                                        y: (item.y +
                                                details.focalPointDelta.dy /
                                                    constraints.maxHeight)
                                            .clamp(0, .82),
                                        scale: widget.editMode
                                            ? (_startScale * details.scale)
                                                .clamp(.75, 1.5)
                                            : item.scale,
                                        rotation: _startRotation,
                                      );
                                    });
                                  },
                                  onScaleEnd: (_) => widget.onChanged(
                                    _items.firstWhere((value) => value.id == item.id),
                                  ),
                                  child: Transform.rotate(
                                    angle: item.rotation,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.scale(
                                          scale: item.scale,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              border: widget.selectedItemId == item.id
                                                  ? Border.all(
                                                      color: Colors.orange,
                                                      width: 2,
                                                    )
                                                  : null,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: RepaintBoundary(
                                              child: _StickerArtwork(asset: asset),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            ..._items.map((item) => _buildTextItem(item, constraints)),
                            if (widget.editMode && selectedItem != null)
                              Positioned(
                                left: selectedItem.x * constraints.maxWidth +
                                    75 +
                                    math.cos(selectedItem.rotation - math.pi / 2) *
                                        68 *
                                        selectedItem.scale -
                                    17,
                                top: selectedItem.y * constraints.maxHeight +
                                    60 +
                                    math.sin(selectedItem.rotation - math.pi / 2) *
                                        68 *
                                        selectedItem.scale -
                                    17,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (details) {
                                    final box = _boardKey.currentContext
                                        ?.findRenderObject() as RenderBox?;
                                    if (box == null) return;
                                    _rotationCenter = box.localToGlobal(Offset(
                                      selectedItem!.x * constraints.maxWidth + 75,
                                      selectedItem.y * constraints.maxHeight + 43,
                                    ));
                                    final delta =
                                        details.globalPosition - _rotationCenter!;
                                    _handleStartAngle =
                                        math.atan2(delta.dy, delta.dx);
                                    _handleStartRotation = selectedItem.rotation;
                                  },
                                  onPanUpdate: (details) {
                                    final center = _rotationCenter;
                                    if (center == null) return;
                                    final index = _items.indexWhere(
                                      (value) => value.id == selectedItem!.id,
                                    );
                                    final current = _items[index];
                                    final delta = details.globalPosition - center;
                                    final angle = math.atan2(delta.dy, delta.dx);
                                    setState(() {
                                      _items[index] = current.copyWith(
                                        rotation: _handleStartRotation +
                                            angle -
                                            _handleStartAngle,
                                      );
                                    });
                                  },
                                  onPanEnd: (_) => widget.onChanged(
                                    _items.firstWhere(
                                        (value) => value.id == selectedItem!.id),
                                  ),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.rotate_right,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.editMode && selectedItem != null)
                              Positioned(
                                left: (selectedItem.x * constraints.maxWidth - 50)
                                    .clamp(4, constraints.maxWidth - 252),
                                top: (selectedItem.y * constraints.maxHeight +
                                        96 * selectedItem.scale)
                                    .clamp(4, constraints.maxHeight - 48),
                                child: _StickerSelectionToolbar(
                                  onAction: (action) {
                                    final current = _items.firstWhere(
                                      (value) => value.id == selectedItem!.id,
                                    );
                                    final asset = assets[current.stickerId];
                                    if (asset != null) {
                                      widget.onToolAction(asset, current, action);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextItem(StickerBoardItem item, BoxConstraints constraints) {
    if (!item.textEnabled || item.textContent.isEmpty) return const SizedBox.shrink();
    final isSelected = _selectedTextId == item.id;
    return Positioned(
      left: (item.textX * constraints.maxWidth).clamp(0.0, constraints.maxWidth - 12),
      top: (item.textY * constraints.maxHeight).clamp(0.0, constraints.maxHeight - 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _selectedTextId = item.id;
          _textController.text = item.textContent;
        }),
        onPanUpdate: (details) {
          final index = _items.indexWhere((v) => v.id == item.id);
          if (index == -1) return;
          setState(() {
            _items[index] = _items[index].copyWith(
              textX: (_items[index].textX + details.delta.dx / constraints.maxWidth)
                  .clamp(0.0, 0.95),
              textY: (_items[index].textY + details.delta.dy / constraints.maxHeight)
                  .clamp(0.0, 0.95),
            );
          });
        },
        onPanEnd: (_) =>
            widget.onChanged(_items.firstWhere((v) => v.id == item.id)),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: Colors.orange, width: 1) : null,
          ),
          child: Text(
            item.textContent,
            style: TextStyle(
              fontSize: 120 * 0.72 * item.scale * item.textSize,
              color: _hexToColor(item.textColor),
              fontFamily: item.textFont.isEmpty ? null : item.textFont,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextEditPanel() {
    final item = _items.where((i) => i.id == _textPanelItemId).firstOrNull;
    if (item == null) return const SizedBox.shrink();

    const colorOptions = ['#FFFFFF', '#000000', '#FF6B00', '#FF3B30', '#007AFF', '#FFD60A'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Switch(
                value: item.textEnabled,
                onChanged: (v) => _updateTextItem(item.copyWith(textEnabled: v)),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'テキストを入力',
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => _updateTextItem(item.copyWith(textContent: v)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 10)),
              Expanded(
                child: Slider(
                  value: item.textSize.clamp(0.02, 0.06),
                  min: 0.02,
                  max: 0.06,
                  divisions: 20,
                  onChanged: (v) {
                    final index = _items.indexWhere((i) => i.id == item.id);
                    if (index != -1) {
                      setState(() => _items[index] = _items[index].copyWith(textSize: v));
                    }
                  },
                  onChangeEnd: (_) =>
                      widget.onChanged(_items.firstWhere((i) => i.id == item.id)),
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 20)),
            ],
          ),
          Row(
            children: [
              ...colorOptions.map((hex) => GestureDetector(
                    onTap: () => _updateTextItem(item.copyWith(textColor: hex)),
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        shape: BoxShape.circle,
                        border: item.textColor == hex
                            ? Border.all(color: Colors.orange, width: 2)
                            : Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                  )),
              const Spacer(),
              DropdownButton<String>(
                value: item.textFont,
                isDense: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: '',
                      child: Text('デフォルト', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(
                      value: 'serif',
                      child: Text('セリフ',
                          style: TextStyle(fontSize: 13, fontFamily: 'serif'))),
                  DropdownMenuItem(
                      value: 'monospace',
                      child: Text('等幅',
                          style: TextStyle(fontSize: 13, fontFamily: 'monospace'))),
                ],
                onChanged: (v) {
                  if (v != null) _updateTextItem(item.copyWith(textFont: v));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateTextItem(StickerBoardItem updated) {
    final index = _items.indexWhere((i) => i.id == updated.id);
    if (index == -1) return;
    setState(() => _items[index] = updated);
    widget.onChanged(updated);
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> exportBoard() async {
    final boundary =
        _boardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File(p.join(
        directory.path,
        'kickxkick_board_${DateTime.now().millisecondsSinceEpoch}.png'));
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await SharePlus.instance
        .share(ShareParams(files: [XFile(file.path)], subject: 'KickxKick Sticker Board'));
  }
}

class _StickerSelectionToolbar extends StatelessWidget {
  const _StickerSelectionToolbar({required this.onAction});

  final ValueChanged<_StickerToolAction> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = <(_StickerToolAction, IconData, String)>[
      (_StickerToolAction.paste, Icons.content_paste, '貼り付け'),
      (_StickerToolAction.duplicate, Icons.copy_outlined, '複製'),
      (_StickerToolAction.delete, Icons.delete_outline, '削除'),
      (_StickerToolAction.zoomIn, Icons.add_circle_outline, '拡大'),
      (_StickerToolAction.zoomOut, Icons.remove_circle_outline, '縮小'),
      (_StickerToolAction.bringFront, Icons.flip_to_front, '最前面'),
    ];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (action) => IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 19,
                  tooltip: action.$3,
                  onPressed: () => onAction(action.$1),
                  icon: Icon(action.$2),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StickerArtwork extends StatelessWidget {
  const _StickerArtwork({
    required this.asset,
    this.size = 120,
    this.onTextPositionChanged,
  });

  final StickerAsset asset;
  final double size;
  final ValueChanged<Offset>? onTextPositionChanged;

  @override
  Widget build(BuildContext context) {
    final image = File(asset.displayPath);
    final text = asset.stickerText?.trim() ?? '';
    final height = size * .72;
    final imageHeight = height;
    final width = size * 1.25;
    final fontSize = size * 0.0288 * asset.textScale;
    final estimatedTextWidth =
        (text.runes.length * fontSize * .72).clamp(fontSize, width * .92);
    final textHeight = fontSize * 1.35;
    final minX = estimatedTextWidth / 2 / width;
    final maxX = 1 - minX;
    final minY = textHeight / 2 / height;
    final maxY = 1 - minY;
    final textX = asset.textX.clamp(minX, maxX);
    final textY = asset.textY.clamp(minY, maxY);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (asset.shadowEnabled)
            Positioned(
              top: 7,
              width: size * 1.08,
              height: imageHeight,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: .55),
                    BlendMode.srcIn,
                  ),
                  child: Image.file(
                    image,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ..._outlineLayers(
            image,
            imageHeight,
            radius: 6,
            color: Color(asset.outerBorderColor),
            count: 20,
          ),
          ..._outlineLayers(
            image,
            imageHeight,
            radius: 3,
            color: Color(asset.innerBorderColor),
            count: 16,
          ),
          Positioned(
            top: 0,
            width: size * 1.08,
            height: imageHeight,
            child: Image.file(
              image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          if (text.isNotEmpty)
            Positioned(
              left: textX * width - estimatedTextWidth / 2,
              top: textY * height - textHeight / 2,
              width: estimatedTextWidth,
              height: textHeight,
              child: GestureDetector(
                onPanUpdate: onTextPositionChanged == null
                    ? null
                    : (details) {
                        onTextPositionChanged!(Offset(
                          (textX + details.delta.dx / width).clamp(minX, maxX),
                          (textY + details.delta.dy / height).clamp(minY, maxY),
                        ));
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _stickerText(text, Color(asset.outerBorderColor), PaintingStyle.stroke, 8),
                    _stickerText(text, Color(asset.innerBorderColor), PaintingStyle.stroke, 5),
                    _stickerText(text, Color(asset.textColor), PaintingStyle.fill, 0),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _outlineLayers(
    File image,
    double height, {
    required double radius,
    required Color color,
    required int count,
  }) {
    return List.generate(count, (index) {
      final angle = index * 2 * 3.141592653589793 / count;
      return Positioned(
        top: 0,
        width: size * 1.08,
        height: height,
        child: Transform.translate(
          offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.file(
              image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
    });
  }

  Widget _stickerText(
    String text,
    Color color,
    PaintingStyle style,
    double strokeWidth,
  ) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'NotoSansJP',
        fontSize: size * 0.0288 * asset.textScale,
        fontWeight: FontWeight.w900,
        height: 1,
        foreground: Paint()
          ..style = style
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = strokeWidth
          ..color = color,
      ),
    );
  }
}
