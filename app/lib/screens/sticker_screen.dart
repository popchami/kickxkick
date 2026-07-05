import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/background_theme.dart';
import '../models/shoe.dart';
import '../models/sticker_asset.dart';
import '../models/sticker_board.dart';
import '../models/brand.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/sticker_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/sticker_repository.dart';
import '../services/background_removal_service.dart'
    show BackgroundRemovalService, CutoutResult;
import '../widgets/app_dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/themed_background.dart';
import 'cutout_adjustment_screen.dart';

class StickerScreen extends ConsumerStatefulWidget {
  const StickerScreen({super.key});

  @override
  ConsumerState<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends ConsumerState<StickerScreen> {
  static const _lastBoardIdKey = 'last_board_id';

  final Map<int, GlobalKey<_StickerBoardState>> _boardKeys = {};
  final Map<int, List<StickerBoardItem>> _boardItemsCache = {};
  final Set<int> _loadingBoardIds = {};
  final _pageController = PageController();
  final _searchController = TextEditingController();
  String _searchText = '';
  int? _selectedBrandId;
  String? _selectedStatus;
  String? _selectedColor;
  bool _editMode = false;
  int? _pasteStickerId;
  StickerAsset? _selectedSticker;
  StickerBoardItem? _selectedBoardItem;
  List<StickerBoard> _boards = [];
  int? _boardId;

  GlobalKey<_StickerBoardState> _boardKeyFor(int boardId) =>
      _boardKeys.putIfAbsent(boardId, () => GlobalKey<_StickerBoardState>());

  String get _currentBoardName {
    final boardId = _boardId;
    if (boardId == null) return 'Sticker';
    for (final board in _boards) {
      if (board.id == boardId) return board.name;
    }
    return 'Sticker';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBoard());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 指定ボードのアイテムをキャッシュになければ取得する（多重取得は防止）。
  Future<void> _loadBoardItems(int boardId) async {
    if (_boardItemsCache.containsKey(boardId) || _loadingBoardIds.contains(boardId)) {
      return;
    }
    _loadingBoardIds.add(boardId);
    final items = await ref.read(stickerRepositoryProvider).getBoardItems(boardId);
    _loadingBoardIds.remove(boardId);
    if (mounted) {
      setState(() => _boardItemsCache[boardId] = items);
    }
  }

  Future<void> _initBoard() async {
    final repository = ref.read(stickerRepositoryProvider);
    var boards = await repository.getBoards();
    if (boards.isEmpty) {
      await repository.ensureDefaultBoard();
      boards = await repository.getBoards();
    }
    final savedIdText = await ref.read(settingsRepositoryProvider).getValue(_lastBoardIdKey);
    final savedId = savedIdText == null ? null : int.tryParse(savedIdText);
    final initialBoard = boards.firstWhere(
      (board) => board.id == savedId,
      orElse: () => boards.first,
    );
    final initialIndex = boards.indexOf(initialBoard);
    final items = await repository.getBoardItems(initialBoard.id);
    if (!mounted) return;
    setState(() {
      _boards = boards;
      _boardId = initialBoard.id;
      _boardItemsCache[initialBoard.id] = items;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
    });
  }

  /// PageViewでボードが切り替わった時の副作用を一元管理する
  /// （スワイプ・ボード一覧からの選択・新規作成後の移動、いずれもここを通る）。
  Future<void> _onBoardPageChanged(int index) async {
    final board = _boards[index];
    setState(() {
      _boardId = board.id;
      _selectedSticker = null;
      _selectedBoardItem = null;
    });
    await ref
        .read(settingsRepositoryProvider)
        .setValue(_lastBoardIdKey, board.id.toString());
    await _loadBoardItems(board.id);
  }

  Future<void> _createBoard(String name) async {
    final repository = ref.read(stickerRepositoryProvider);
    final id = await repository.createBoard(name);
    final boards = await repository.getBoards();
    final items = await repository.getBoardItems(id);
    final index = boards.indexWhere((board) => board.id == id);
    if (!mounted) return;
    setState(() {
      _boards = boards;
      _boardItemsCache[id] = items;
    });
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  Future<void> _deleteBoard(StickerBoard board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ボードを削除しますか？'),
        content: Text(
          '「${board.name}」を削除します。この操作は取り消せません。\n'
          'ボードに貼り付けたステッカー自体は削除されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repository = ref.read(stickerRepositoryProvider);
    await repository.deleteBoard(board.id);
    final boards = await repository.getBoards();
    if (!mounted) return;
    final wasActive = board.id == _boardId;
    setState(() {
      _boards = boards;
      _boardItemsCache.remove(board.id);
      _boardKeys.remove(board.id);
    });
    final targetBoard = wasActive
        ? boards.first
        : boards.firstWhere((b) => b.id == _boardId, orElse: () => boards.first);
    final targetIndex = boards.indexOf(targetBoard);
    if (wasActive) {
      await _onBoardPageChanged(targetIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
    });
  }

  void _showBoardPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final board in _boards)
              ListTile(
                leading: Icon(
                  board.id == _boardId
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: board.id == _boardId
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(board.name),
                trailing: _boards.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteBoard(board);
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  final index = _boards.indexOf(board);
                  if (index != -1) _pageController.jumpToPage(index);
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('＋新しいボード'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateBoardDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateBoardDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新しいボード'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'ボード名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('作成'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _createBoard(name);
  }

  /// PageView.builderの1ページ分。board.idをキーに_boardItemsCacheを
  /// 明示的に読み書きする（隣接ページの先行構築時に_boardIdへ暗黙依存しないため）。
  Widget _buildBoardPage(
    StickerBoard board,
    List<StickerAsset> stickers,
    List<StickerAsset> visibleStickers,
    List<Shoe> shoes,
  ) {
    if (visibleStickers.isEmpty) {
      return const Center(child: Text('該当するステッカーがありません'));
    }
    final items = _boardItemsCache[board.id];
    if (items == null) {
      _loadBoardItems(board.id);
      return const Center(child: CircularProgressIndicator());
    }
    return _StickerBoard(
      key: _boardKeyFor(board.id),
      stickers: visibleStickers,
      items: items,
      editMode: _editMode,
      selectedItemId: board.id == _boardId ? _selectedBoardItem?.id : null,
      backgroundTheme: board.backgroundTheme,
      onPaste: (position) => _pasteStickerAt(board.id, stickers, position),
      onChanged: (item) {
        final current = _boardItemsCache[board.id] ?? const <StickerBoardItem>[];
        final idx = current.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _boardItemsCache[board.id] = [
            for (final i in current) i.id == item.id ? item : i,
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
          _handleStickerTool(asset, item, action, shoes, board.id),
    );
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
        title: InkWell(
          onTap: _boards.isEmpty ? null : _showBoardPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(_currentBoardName, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _boardId == null
                ? null
                : () => _boardKeyFor(_boardId!).currentState?.exportBoard(),
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
                child: _boards.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                        controller: _pageController,
                        physics: _editMode
                            ? const NeverScrollableScrollPhysics()
                            : const PageScrollPhysics(),
                        onPageChanged: _onBoardPageChanged,
                        itemCount: _boards.length,
                        itemBuilder: (context, index) => _buildBoardPage(
                          _boards[index],
                          stickers,
                          visibleStickers,
                          shoes,
                        ),
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
    final repository = ref.read(stickerRepositoryProvider);
    await repository.pasteToBoard(boardId, selected.id, x: position.dx, y: position.dy);
    final newItems = await repository.getBoardItems(boardId);
    if (mounted) setState(() => _boardItemsCache[boardId] = newItems);
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
      final boardId = _boardId ?? await repository.ensureDefaultBoard();
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
      if (mounted) setState(() => _boardItemsCache[boardId] = newItems);
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
            initialCropOffsetXFrac: asset.cropOffsetXFrac,
            initialCropOffsetYFrac: asset.cropOffsetYFrac,
            initialCropWidthFrac: asset.cropWidthFrac,
            initialCropHeightFrac: asset.cropHeightFrac,
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
    List<Shoe> shoes,
    int boardId,
  ) async {
    final repository = ref.read(stickerRepositoryProvider);
    List<StickerBoardItem> current() =>
        _boardItemsCache[boardId] ?? const <StickerBoardItem>[];
    switch (action) {
      case _StickerToolAction.paste:
        setState(() => _pasteStickerId = asset.id);
      case _StickerToolAction.duplicate:
        // DB INSERT が必要なため await を維持（新アイテムの ID を DB が採番）
        if (!await _checkBoardCapacity(item.boardId)) return;
        final newItem = await repository.duplicateBoardItem(item);
        if (mounted) {
          setState(() => _boardItemsCache[boardId] = [...current(), newItem]);
        }
      case _StickerToolAction.delete:
        // UI 先行・DB バックグラウンド
        setState(() {
          _selectedSticker = null;
          _selectedBoardItem = null;
          _boardItemsCache[boardId] =
              current().where((i) => i.id != item.id).toList();
        });
        repository.deleteBoardItem(item.id);
      case _StickerToolAction.zoomIn:
        final zoomedIn = item.copyWith(scale: (item.scale + .1).clamp(.4, 2.0));
        setState(() {
          _boardItemsCache[boardId] = [
            for (final i in current()) i.id == zoomedIn.id ? zoomedIn : i,
          ];
        });
        repository.updateBoardItem(zoomedIn);
      case _StickerToolAction.zoomOut:
        final zoomedOut = item.copyWith(scale: (item.scale - .1).clamp(.4, 2.0));
        setState(() {
          _boardItemsCache[boardId] = [
            for (final i in current()) i.id == zoomedOut.id ? zoomedOut : i,
          ];
        });
        repository.updateBoardItem(zoomedOut);
      case _StickerToolAction.bringFront:
        final maxZ = current().fold(0, (m, i) => i.zIndex > m ? i.zIndex : m);
        final fronted = item.copyWith(zIndex: maxZ + 1);
        setState(() {
          _boardItemsCache[boardId] = ([
            for (final i in current()) i.id == item.id ? fronted : i,
          ]..sort((a, b) => a.zIndex.compareTo(b.zIndex)));
        });
        repository.bringToFront(item);
      case _StickerToolAction.editDesign:
        await _editSticker(asset, shoes, action: _StickerEditAction.design);
      case _StickerToolAction.editCutout:
        await _editSticker(asset, shoes, action: _StickerEditAction.cutout);
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
    await showAppMessage(
      context,
      title: 'Premiumへのご案内',
      message: isPremium
          ? 'Premiumでは1ボード30枚まで貼り付けできます。'
          : '無料版では1ボードにステッカーを10枚まで貼り付けできます。もっと貼り付けるにはPremiumへのアップグレードが必要です。',
    );
    return false;
  }
}

enum _StickerBoardCommand { toggleEdit, cutout }

enum _StickerEditAction { cutout, design }

enum _StickerToolAction {
  paste,
  duplicate,
  delete,
  zoomIn,
  zoomOut,
  bringFront,
  editDesign,
  editCutout,
}

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
    required this.backgroundTheme,
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
  final BackgroundTheme backgroundTheme;
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ThemedBackground(
                            theme: widget.backgroundTheme,
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
                                // ステッカーは中心(x*maxWidth+75, y*maxHeight+43.2)を
                                // 基準に拡大縮小されるため、はみ出す量のうち固定部分(75/43.2)
                                // と拡大率に応じて変わる部分(scale倍)を分けて計算する。
                                left: (selectedItem.x * constraints.maxWidth +
                                        75 -
                                        147)
                                    .clamp(4, constraints.maxWidth - 294),
                                top: (selectedItem.y * constraints.maxHeight +
                                        43.2 +
                                        43.2 * selectedItem.scale +
                                        8)
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
          children: [
            ...actions.map(
              (action) => IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 19,
                tooltip: action.$3,
                onPressed: () => onAction(action.$1),
                icon: Icon(action.$2),
              ),
            ),
            PopupMenuButton<_StickerToolAction>(
              tooltip: '編集',
              icon: const Icon(Icons.edit_outlined, size: 19),
              onSelected: onAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _StickerToolAction.editDesign,
                  child: Text('デザインを編集'),
                ),
                PopupMenuItem(
                  value: _StickerToolAction.editCutout,
                  child: Text('切り抜きを編集'),
                ),
              ],
            ),
          ],
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
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 800);
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
    // 文字数×係数の近似値ではなく、TextPainterで実際に描画される幅・高さを
    // 正確に測定する。プレビュー(大きいsize)とボード(小さいsize)で
    // 見た目の位置が微妙にズレる問題の原因だったため、実測に統一する。
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final estimatedTextWidth = textPainter.width.clamp(fontSize, width * .92);
    final textHeight = textPainter.height;
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
                artworkSize: size,
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
                // デザイン編集画面(onTextPositionChangedあり)でのみ、
                // ステッカー本体の選択枠と同じオレンジ枠線で移動可能な範囲を示す。
                child: DecoratedBox(
                  decoration: widget.onTextPositionChanged == null
                      ? const BoxDecoration()
                      : BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _stickerText(text, Color(asset.textColor), PaintingStyle.fill, 0, size, asset.textScale),
                    ],
                  ),
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
    required this.artworkSize,
  });

  final ui.Image image;
  final bool shadowEnabled;
  final Color outerBorderColor;
  final Color innerBorderColor;
  final double artworkSize;

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

    // フチの太さはsize=120基準(元の固定値6px/3px)の比率を保ったまま
    // artworkSizeに比例させる。デザイン編集画面など大きいsizeで表示した時も
    // 文字サイズ(size * 0.0288)と同じようにフチが太くなり、見た目の比率が崩れない。
    final outerBorderWidth = artworkSize * 0.05;
    final innerBorderWidth = artworkSize * 0.025;
    // フチのギザギザを抑えるための弱いぼかし。色・太さがはっきり分かる程度に留める。
    final borderBlurSigma = artworkSize * 0.012;
    // シャドウの縦オフセットもsize=120基準(元の固定値7px)の比率を保ったまま
    // artworkSizeに比例させる。
    final shadowOffsetY = artworkSize * (7 / 120);

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
        Rect.fromLTWH(drawX, drawY + shadowOffsetY, drawW, drawH),
        shadowPaint,
      );
    }

    // 2. 外枠: radius=outerBorderWidth で 16 方向に重ねて描画し、
    // 弱いぼかしを加えることで輪郭のギザギザ・多角形的なカクつきを抑える。
    final outerPaint = Paint()
      ..colorFilter = ColorFilter.mode(outerBorderColor, BlendMode.srcIn)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, borderBlurSigma);
    for (var i = 0; i < 16; i++) {
      final angle = i * 2 * math.pi / 16;
      canvas.drawImageRect(
        image, srcRect,
        Rect.fromLTWH(
          drawX + outerBorderWidth * math.cos(angle),
          drawY + outerBorderWidth * math.sin(angle),
          drawW, drawH,
        ),
        outerPaint,
      );
    }

    // 3. 内枠: radius=innerBorderWidth で 8 方向に重ねて描画し、外枠と同様に弱いぼかしを加える。
    final innerPaint = Paint()
      ..colorFilter = ColorFilter.mode(innerBorderColor, BlendMode.srcIn)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, borderBlurSigma);
    for (var i = 0; i < 8; i++) {
      final angle = i * 2 * math.pi / 8;
      canvas.drawImageRect(
        image, srcRect,
        Rect.fromLTWH(
          drawX + innerBorderWidth * math.cos(angle),
          drawY + innerBorderWidth * math.sin(angle),
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
      old.innerBorderColor != innerBorderColor ||
      old.artworkSize != artworkSize;
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
                  // デザイン編集画面は背景テーマの影響を受けない固定のグレー。
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
