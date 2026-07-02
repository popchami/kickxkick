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
import '../services/background_removal_service.dart'
    show BackgroundRemovalService, CutoutResult;
import '../widgets/empty_state.dart';
import 'cutout_adjustment_screen.dart';

class StickerScreen extends ConsumerStatefulWidget {
  const StickerScreen({super.key});

  @override
  ConsumerState<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends ConsumerState<StickerScreen> {
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
  int? _boardId;
  List<StickerBoardItem> _boardItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBoard());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initBoard() async {
    final repository = ref.read(stickerRepositoryProvider);
    final boardId = await repository.ensureDefaultBoard();
    final items = await repository.getBoardItems(boardId);
    if (mounted) setState(() { _boardId = boardId; _boardItems = items; });
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
                    : _boardId == null
                        ? const Center(child: CircularProgressIndicator())
                        : _StickerBoard(
                            key: _boardKey,
                            stickers: visibleStickers,
                            items: _boardItems,
                            editMode: _editMode,
                            selectedItemId: _selectedBoardItem?.id,
                            onPaste: (position) => _pasteStickerAt(stickers, position),
                            onChanged: (item) {
                              final idx = _boardItems.indexWhere((i) => i.id == item.id);
                              if (idx != -1) {
                                _boardItems = [
                                  for (final i in _boardItems) i.id == item.id ? item : i,
                                ];
                              }
                              ref.read(stickerRepositoryProvider).updateBoardItem(item);
                            },
                            onEdit: (asset, item) => setState(() {
                              _selectedSticker = asset;
                              _selectedBoardItem = item;
                            }),
                            onDesign: (asset, item) =>
                                _editSticker(asset, shoes, action: _StickerEditAction.design),
                            onToolAction: (asset, item, action) =>
                                _handleStickerTool(asset, item, action),
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

  Future<void> _pasteStickerAt(
    List<StickerAsset> stickers,
    Offset position,
  ) async {
    final boardId = _boardId;
    if (!_editMode || stickers.isEmpty || boardId == null) return;
    if (!await _checkBoardCapacity(boardId)) return;
    StickerAsset? selected;
    for (final asset in stickers) {
      if (asset.id == _pasteStickerId) {
        selected = asset;
        break;
      }
    }
    if (selected == null || !mounted) return;
    final repository = ref.read(stickerRepositoryProvider);
    await repository.pasteToBoard(boardId, selected.id, x: position.dx, y: position.dy);
    final newItems = await repository.getBoardItems(boardId);
    if (mounted) setState(() => _boardItems = newItems);
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
      var cropOffsetXFrac = photo.cropOffsetXFrac;
      var cropOffsetYFrac = photo.cropOffsetYFrac;
      var cropWidthFrac = photo.cropWidthFrac;
      var cropHeightFrac = photo.cropHeightFrac;
      if (cutoutPath == null || !await File(cutoutPath).exists()) {
        final result = await BackgroundRemovalService()
            .removeEdgeBackground(photo.filePath, shoe.id!);
        cutoutPath = result.cutoutPath;
        cropOffsetXFrac = result.offsetXFrac;
        cropOffsetYFrac = result.offsetYFrac;
        cropWidthFrac = result.widthFrac;
        cropHeightFrac = result.heightFrac;
        await ref.read(photoRepositoryProvider).updatePhoto(
              photo.copyWith(
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
        cropOffsetXFrac: cropOffsetXFrac,
        cropOffsetYFrac: cropOffsetYFrac,
        cropWidthFrac: cropWidthFrac,
        cropHeightFrac: cropHeightFrac,
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
      final newItems = await repository.getBoardItems(boardId);
      if (mounted) setState(() => _boardItems = newItems);
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
    return Navigator.push<_StickerDesign>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _StickerDesignerPage(
          shoe: shoe,
          cutoutPath: cutoutPath,
          initialText: text,
          initialTextColor: textColor,
          initialInnerColor: innerColor,
          initialOuterColor: outerColor,
          initialShadow: shadow,
          initialTextScale: textScale,
          initialTextX: textX,
          initialTextY: textY,
          colors: colors,
        ),
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
    var cropOffsetXFrac = asset.cropOffsetXFrac;
    var cropOffsetYFrac = asset.cropOffsetYFrac;
    var cropWidthFrac = asset.cropWidthFrac;
    var cropHeightFrac = asset.cropHeightFrac;
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
      final editResult = await Navigator.push<CutoutResult>(
        context,
        MaterialPageRoute(
          builder: (_) => CutoutAdjustmentScreen(
            sourcePath: asset.sourcePath,
            shoeId: asset.shoeId,
            initialCutoutPath: asset.stickerPath,
          ),
        ),
      );
      if (editResult == null || !mounted) return;
      stickerPath = editResult.cutoutPath;
      cropOffsetXFrac = editResult.offsetXFrac;
      cropOffsetYFrac = editResult.offsetYFrac;
      cropWidthFrac = editResult.widthFrac;
      cropHeightFrac = editResult.heightFrac;
      final photo = await ref.read(photoRepositoryProvider).getMainPhoto(asset.shoeId);
      if (photo != null) {
        await ref.read(photoRepositoryProvider).updatePhoto(
              photo.copyWith(
                cutoutPath: editResult.cutoutPath,
                cutoutMaskPath: editResult.maskPath,
                cutoutThreshold: editResult.threshold,
                cutoutEngine: editResult.engine,
                cutoutSmoothing: editResult.smoothing,
                cutoutAntialiasing: editResult.antialiasing,
                cropOffsetXFrac: editResult.offsetXFrac,
                cropOffsetYFrac: editResult.offsetYFrac,
                cropWidthFrac: editResult.widthFrac,
                cropHeightFrac: editResult.heightFrac,
              ),
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
          cropOffsetXFrac: cropOffsetXFrac,
          cropOffsetYFrac: cropOffsetYFrac,
          cropWidthFrac: cropWidthFrac,
          cropHeightFrac: cropHeightFrac,
        );
    ref.invalidate(stickersProvider);
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
        // DB INSERT が必要なため await を維持（新アイテムの ID を DB が採番）
        if (!await _checkBoardCapacity(item.boardId)) return;
        final newItem = await repository.duplicateBoardItem(item);
        if (mounted) setState(() => _boardItems = [..._boardItems, newItem]);
      case _StickerToolAction.delete:
        // UI 先行・DB バックグラウンド
        setState(() {
          _selectedSticker = null;
          _selectedBoardItem = null;
          _boardItems = _boardItems.where((i) => i.id != item.id).toList();
        });
        repository.deleteBoardItem(item.id);
      case _StickerToolAction.zoomIn:
        final zoomedIn = item.copyWith(scale: (item.scale + .1).clamp(.4, 2.0));
        setState(() {
          _boardItems = [for (final i in _boardItems) i.id == zoomedIn.id ? zoomedIn : i];
        });
        repository.updateBoardItem(zoomedIn);
      case _StickerToolAction.zoomOut:
        final zoomedOut = item.copyWith(scale: (item.scale - .1).clamp(.4, 2.0));
        setState(() {
          _boardItems = [for (final i in _boardItems) i.id == zoomedOut.id ? zoomedOut : i];
        });
        repository.updateBoardItem(zoomedOut);
      case _StickerToolAction.bringFront:
        final maxZ = _boardItems.fold(0, (m, i) => i.zIndex > m ? i.zIndex : m);
        final fronted = item.copyWith(zIndex: maxZ + 1);
        setState(() {
          _boardItems = ([
            for (final i in _boardItems) i.id == item.id ? fronted : i,
          ]..sort((a, b) => a.zIndex.compareTo(b.zIndex)));
        });
        repository.bringToFront(item);
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
  double _startScale = 1;
  double _startRotation = 0;
  Offset? _rotationCenter;
  double _handleStartAngle = 0;
  double _handleStartRotation = 0;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant _StickerBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      setState(() => _items = [...widget.items]);
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
                                key: ValueKey(item.id),
                                left: item.x * constraints.maxWidth,
                                top: item.y * constraints.maxHeight,
                                child: GestureDetector(
                                  onTap: widget.editMode
                                      ? () => widget.onEdit(asset, item)
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
                                                .clamp(.4, 2.0)
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
    return Positioned(
      key: ValueKey('text_${item.id}'),
      left: (item.textX * constraints.maxWidth).clamp(0.0, constraints.maxWidth - 12),
      top: (item.textY * constraints.maxHeight).clamp(0.0, constraints.maxHeight - 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
        child: Text(
          item.textContent,
          style: TextStyle(
            fontSize: 120 * 0.72 * item.scale * item.textSize,
            color: _hexToColor(item.textColor),
            fontFamily: item.textFont.isEmpty ? null : item.textFont,
            decoration: TextDecoration.none,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
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

class _StickerArtwork extends StatefulWidget {
  const _StickerArtwork({
    required this.asset,
    this.size = 120,
    this.onTextPositionChanged,
  });

  final StickerAsset asset;
  final double size;
  final ValueChanged<Offset>? onTextPositionChanged;

  @override
  State<_StickerArtwork> createState() => _StickerArtworkState();
}

class _StickerArtworkState extends State<_StickerArtwork> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_StickerArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.displayPath != widget.asset.displayPath) {
      _image = null;
      _loadImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.asset.displayPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 300);
    final frame = await codec.getNextFrame();
    if (mounted) {
      _image?.dispose();
      setState(() => _image = frame.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final size = widget.size;
    final text = asset.stickerText?.trim() ?? '';
    final height = size * .72;
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
          // 案A: 38個の Image.file を1つの CustomPaint に集約
          if (_image != null)
            CustomPaint(
              size: Size(width, height),
              painter: _StickerArtworkPainter(
                image: _image!,
                shadowEnabled: asset.shadowEnabled,
                outerBorderColor: Color(asset.outerBorderColor),
                innerBorderColor: Color(asset.innerBorderColor),
              ),
            ),
          if (text.isNotEmpty)
            Positioned(
              left: textX * width - estimatedTextWidth / 2,
              top: textY * height - textHeight / 2,
              width: estimatedTextWidth,
              height: textHeight,
              child: GestureDetector(
                onPanUpdate: widget.onTextPositionChanged == null
                    ? null
                    : (details) {
                        widget.onTextPositionChanged!(Offset(
                          (textX + details.delta.dx / width).clamp(minX, maxX),
                          (textY + details.delta.dy / height).clamp(minY, maxY),
                        ));
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _stickerText(text, Color(asset.textColor), PaintingStyle.fill, 0, size, asset.textScale),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stickerText(
    String text,
    Color color,
    PaintingStyle style,
    double strokeWidth,
    double size,
    double textScale,
  ) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'NotoSansJP',
        fontSize: size * 0.0288 * textScale,
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

class _StickerArtworkPainter extends CustomPainter {
  const _StickerArtworkPainter({
    required this.image,
    required this.shadowEnabled,
    required this.outerBorderColor,
    required this.innerBorderColor,
  });

  final ui.Image image;
  final bool shadowEnabled;
  final Color outerBorderColor;
  final Color innerBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 画像エリアは幅の 1.08/1.25、高さはフル
    final imgAreaW = size.width * (1.08 / 1.25);
    final imgAreaH = size.height;
    final centerX = (size.width - imgAreaW) / 2;

    // BoxFit.contain: 画像を imgAreaW × imgAreaH に収まるようスケール
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final scale = math.min(imgAreaW / imgW, imgAreaH / imgH);
    final drawW = imgW * scale;
    final drawH = imgH * scale;
    final drawX = centerX + (imgAreaW - drawW) / 2;
    final drawY = (imgAreaH - drawH) / 2;
    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

    // 1. シャドウ（MaskFilter.blur でガウスぼかし）
    if (shadowEnabled) {
      final shadowPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.black.withValues(alpha: .55),
          BlendMode.srcIn,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawImageRect(
        image, srcRect,
        Rect.fromLTWH(drawX, drawY + 7, drawW, drawH),
        shadowPaint,
      );
    }

    // 2. 外枠: radius=6 で 8 方向に描画
    final outerPaint = Paint()
      ..colorFilter = ColorFilter.mode(outerBorderColor, BlendMode.srcIn);
    for (var i = 0; i < 8; i++) {
      final angle = i * 2 * math.pi / 8;
      canvas.drawImageRect(
        image, srcRect,
        Rect.fromLTWH(
          drawX + 6 * math.cos(angle),
          drawY + 6 * math.sin(angle),
          drawW, drawH,
        ),
        outerPaint,
      );
    }

    // 3. 内枠: radius=3 で 4 方向に描画
    final innerPaint = Paint()
      ..colorFilter = ColorFilter.mode(innerBorderColor, BlendMode.srcIn);
    for (var i = 0; i < 4; i++) {
      final angle = i * 2 * math.pi / 4;
      canvas.drawImageRect(
        image, srcRect,
        Rect.fromLTWH(
          drawX + 3 * math.cos(angle),
          drawY + 3 * math.sin(angle),
          drawW, drawH,
        ),
        innerPaint,
      );
    }

    // 4. 本体画像
    canvas.drawImageRect(image, srcRect, Rect.fromLTWH(drawX, drawY, drawW, drawH), Paint());
  }

  @override
  bool shouldRepaint(_StickerArtworkPainter old) =>
      old.image != image ||
      old.shadowEnabled != shadowEnabled ||
      old.outerBorderColor != outerBorderColor ||
      old.innerBorderColor != innerBorderColor;
}

class _StickerDesignerPage extends StatefulWidget {
  const _StickerDesignerPage({
    required this.shoe,
    required this.cutoutPath,
    required this.initialText,
    required this.initialTextColor,
    required this.initialInnerColor,
    required this.initialOuterColor,
    required this.initialShadow,
    required this.initialTextScale,
    required this.initialTextX,
    required this.initialTextY,
    required this.colors,
  });

  final Shoe shoe;
  final String cutoutPath;
  final String initialText;
  final int initialTextColor;
  final int initialInnerColor;
  final int initialOuterColor;
  final bool initialShadow;
  final double initialTextScale;
  final double initialTextX;
  final double initialTextY;
  final List<int> colors;

  @override
  State<_StickerDesignerPage> createState() => _StickerDesignerPageState();
}

class _StickerDesignerPageState extends State<_StickerDesignerPage> {
  late String _text;
  late int _textColor;
  late int _innerColor;
  late int _outerColor;
  late bool _shadow;
  late double _textScale;
  late double _textX;
  late double _textY;

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;
    _textColor = widget.initialTextColor;
    _innerColor = widget.initialInnerColor;
    _outerColor = widget.initialOuterColor;
    _shadow = widget.initialShadow;
    _textScale = widget.initialTextScale;
    _textX = widget.initialTextX;
    _textY = widget.initialTextY;
  }

  @override
  Widget build(BuildContext context) {
    final preview = StickerAsset(
      id: 0,
      shoeId: widget.shoe.id!,
      sourcePath: widget.cutoutPath,
      stickerPath: widget.cutoutPath,
      stickerText: _text,
      textColor: _textColor,
      innerBorderColor: _innerColor,
      outerBorderColor: _outerColor,
      shadowEnabled: _shadow,
      textScale: _textScale,
      textX: _textX,
      textY: _textY,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ステッカーデザイン'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        leadingWidth: 88,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _StickerDesign(
                text: _text.trim().isEmpty ? null : _text.trim(),
                textColor: _textColor,
                innerBorderColor: _innerColor,
                outerBorderColor: _outerColor,
                shadowEnabled: _shadow,
                textScale: _textScale,
                textX: _textX,
                textY: _textY,
              ),
            ),
            child: const Text('作成'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const previewPadding = 12.0;
            final size = (constraints.maxWidth - previewPadding * 2) / 1.25;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(previewPadding),
                  color: const Color(0xFFF3E7D3),
                  alignment: Alignment.center,
                  child: _StickerArtwork(
                    asset: preview,
                    size: size,
                    onTextPositionChanged: (pos) => setState(() {
                      _textX = pos.dx;
                      _textY = pos.dy;
                    }),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: _text,
                          maxLength: 15,
                          decoration: const InputDecoration(
                            labelText: 'ステッカーテキスト',
                            helperText: '靴詳細の文字を初期値として使用します',
                          ),
                          onChanged: (v) => setState(() => _text = v),
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 64, child: Text('文字サイズ')),
                            Expanded(
                              child: Slider(
                                value: _textScale,
                                min: .6,
                                max: 1.6,
                                divisions: 20,
                                onChanged: (v) => setState(() => _textScale = v),
                              ),
                            ),
                          ],
                        ),
                        _palette('文字色', _textColor, (v) => setState(() => _textColor = v)),
                        _palette('内フチ（標準：白）', _innerColor, (v) => setState(() => _innerColor = v)),
                        _palette('外フチ（標準：オレンジ）', _outerColor, (v) => setState(() => _outerColor = v)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Shadow'),
                          value: _shadow,
                          onChanged: (v) => setState(() => _shadow = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _palette(String label, int selected, ValueChanged<int> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.colors.map((value) {
            final active = value == selected;
            return InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => onSelect(value),
              child: Container(
                width: 34,
                height: 34,
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
                        size: 19,
                        color: value == 0xFFFFFFFF ? Colors.black : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
