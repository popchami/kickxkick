import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/brand.dart';
import '../models/shelf.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/collection_filter_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shelf_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/shelf_repository.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/shoe_card.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

const _collectionColorOptions = <(String, Color?)>[
  ('ブラック', Colors.black),
  ('ホワイト', Colors.white),
  ('グレー', Colors.grey),
  ('レッド', Colors.red),
  ('ブルー', Colors.blue),
  ('グリーン', Colors.green),
  ('イエロー', Colors.yellow),
  ('ブラウン', Colors.brown),
  ('ベージュ', Color(0xFFD7C4A3)),
  ('ピンク', Colors.pink),
  ('パープル', Colors.purple),
  ('オレンジ', Colors.orange),
  ('ネイビー', Color(0xFF1D3557)),
  ('サックス', Color(0xFF87CEEB)),
  ('カーキ', Color(0xFF6B6B3F)),
  ('オリーブ', Color(0xFF808000)),
  ('シルバー', Color(0xFFC0C0C0)),
  ('ゴールド', Color(0xFFD4AF37)),
  ('ワイン', Color(0xFF722F37)),
  ('クリーム', Color(0xFFFFFDD0)),
  ('マルチカラー', null),
  ('その他', null),
];

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  static const _lastShelfIdKey = 'last_shelf_id';

  final _searchController = TextEditingController();
  final _pageController = PageController();
  final Map<int, GlobalKey> _shareKeys = {};
  String _searchText = '';
  List<Shelf> _shelves = [];
  int? _shelfId;
  bool _isDragging = false;

  GlobalKey _shareKeyFor(int shelfId) =>
      _shareKeys.putIfAbsent(shelfId, () => GlobalKey());

  String get _currentShelfName {
    final shelfId = _shelfId;
    if (shelfId == null) return 'コレクション';
    for (final shelf in _shelves) {
      if (shelf.id == shelfId) return shelf.name;
    }
    return 'コレクション';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initShelves());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initShelves() async {
    final repository = ref.read(shelfRepositoryProvider);
    var shelves = await repository.getShelves();
    if (shelves.isEmpty) {
      await repository.ensureDefaultShelf();
      shelves = await repository.getShelves();
    }
    final savedIdText =
        await ref.read(settingsRepositoryProvider).getValue(_lastShelfIdKey);
    final savedId = savedIdText == null ? null : int.tryParse(savedIdText);
    final initialShelf = shelves.firstWhere(
      (shelf) => shelf.id == savedId,
      orElse: () => shelves.first,
    );
    final initialIndex = shelves.indexOf(initialShelf);
    if (!mounted) return;
    setState(() {
      _shelves = shelves;
      _shelfId = initialShelf.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
    });
  }

  /// PageViewで棚が切り替わった時の副作用を一元管理する
  /// （スワイプ・棚一覧からの選択・新規作成後の移動、いずれもここを通る）。
  Future<void> _onShelfPageChanged(int index) async {
    final shelf = _shelves[index];
    setState(() => _shelfId = shelf.id);
    await ref
        .read(settingsRepositoryProvider)
        .setValue(_lastShelfIdKey, shelf.id.toString());
  }

  /// 無料版で棚が既に上限(1枚)ある場合はPremium案内を表示してブロックする。
  Future<bool> _checkShelfLimit() async {
    final isPremium =
        await ref.read(settingsRepositoryProvider).getValue('is_premium') ==
            'true';
    final canCreate = await ref
        .read(shelfRepositoryProvider)
        .canCreateShelf(isPremium: isPremium);
    if (canCreate) return true;
    if (!mounted) return false;
    await showAppMessage(
      context,
      title: 'Premiumへのご案内',
      message: '無料版では棚を1枚まで作成できます。複数の棚を作るにはPremiumへのアップグレードが必要です。',
    );
    return false;
  }

  Future<void> _createShelf(String name) async {
    if (!await _checkShelfLimit()) return;
    final repository = ref.read(shelfRepositoryProvider);
    final id = await repository.createShelf(name);
    final shelves = await repository.getShelves();
    final index = shelves.indexWhere((shelf) => shelf.id == id);
    if (!mounted) return;
    setState(() => _shelves = shelves);
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  Future<void> _deleteShelf(Shelf shelf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('棚を削除しますか？'),
        content: Text(
          '「${shelf.name}」を削除します。この操作は取り消せません。\n'
          '棚に置いた靴のデータ自体は削除されません。',
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
    final repository = ref.read(shelfRepositoryProvider);
    await repository.deleteShelf(shelf.id);
    ref.invalidate(shelfItemsProvider(shelf.id));
    final shelves = await repository.getShelves();
    if (!mounted) return;
    final wasActive = shelf.id == _shelfId;
    setState(() {
      _shelves = shelves;
      _shareKeys.remove(shelf.id);
    });
    final targetShelf = wasActive
        ? shelves.first
        : shelves.firstWhere((s) => s.id == _shelfId, orElse: () => shelves.first);
    final targetIndex = shelves.indexOf(targetShelf);
    if (wasActive) {
      await _onShelfPageChanged(targetIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
    });
  }

  void _showShelfPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final shelf in _shelves)
              ListTile(
                leading: Icon(
                  shelf.id == _shelfId
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: shelf.id == _shelfId
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(shelf.name),
                trailing: _shelves.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteShelf(shelf);
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  final index = _shelves.indexOf(shelf);
                  if (index != -1) _pageController.jumpToPage(index);
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('＋新しい棚'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateShelfDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateShelfDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新しい棚'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '棚の名前'),
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
    await _createShelf(name);
  }

  @override
  Widget build(BuildContext context) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final collectionFilter = ref.watch(collectionFilterProvider);
    final shelfId = _shelfId;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _shelves.isEmpty ? null : _showShelfPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(_currentShelfName, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                shelfId == null ? null : () => _showAddShoeSheet(shelfId),
            icon: const Icon(Icons.add),
            tooltip: '棚に追加',
          ),
          IconButton(
            onPressed: _shareCollection,
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: '棚を共有',
          ),
        ],
      ),
      body: shoesAsync.when(
        data: (shoes) {
          if (shoes.isEmpty) {
            return EmptyState(
              icon: Icons.collections_outlined,
              title: 'あなたのミュージアムは空です',
              description: '最初の1足を登録しましょう',
              actionLabel: '最初のスニーカーを登録',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ShoeFormScreen(),
                  ),
                );
              },
            );
          }

          if (shelfId == null || _shelves.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return brandsAsync.when(
            data: (brands) => _CollectionContent(
              shoes: shoes,
              shelves: _shelves,
              pageController: _pageController,
              shareKeyFor: _shareKeyFor,
              onPageChanged: _onShelfPageChanged,
              isDragging: _isDragging,
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: () => setState(() => _isDragging = false),
              brands: brands,
              selectedBrandId: collectionFilter.brandId,
              selectedStatus: collectionFilter.status,
              selectedColor: collectionFilter.color,
              searchText: _searchText,
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              onBrandSelected: (brandId) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: brandId,
                      status: collectionFilter.status,
                      color: collectionFilter.color,
                    );
              },
              onStatusSelected: (status) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: collectionFilter.brandId,
                      status: status,
                      color: collectionFilter.color,
                    );
              },
              onColorSelected: (color) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: collectionFilter.brandId,
                      status: collectionFilter.status,
                      color: color,
                    );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _CollectionContent(
              shoes: shoes,
              shelves: _shelves,
              pageController: _pageController,
              shareKeyFor: _shareKeyFor,
              onPageChanged: _onShelfPageChanged,
              isDragging: _isDragging,
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: () => setState(() => _isDragging = false),
              brands: const [],
              selectedBrandId: collectionFilter.brandId,
              selectedStatus: collectionFilter.status,
              selectedColor: collectionFilter.color,
              searchText: _searchText,
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              onBrandSelected: (brandId) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: brandId,
                      status: collectionFilter.status,
                      color: collectionFilter.color,
                    );
              },
              onStatusSelected: (status) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: collectionFilter.brandId,
                      status: status,
                      color: collectionFilter.color,
                    );
              },
              onColorSelected: (color) {
                ref.read(collectionFilterProvider.notifier).state =
                    CollectionFilter(
                      brandId: collectionFilter.brandId,
                      status: collectionFilter.status,
                      color: color,
                    );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }

  Future<void> _shareCollection() async {
    final shelfId = _shelfId;
    if (shelfId == null) return;
    final boundary = _shareKeys[shelfId]?.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File(p.join(
      directory.path,
      'kickxkick_collection_${DateTime.now().millisecondsSinceEpoch}.png',
    ));
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'KickxKick Collection'),
    );
  }

  Future<void> _showAddShoeSheet(int shelfId) async {
    final allShoes = ref.read(shoesProvider).value ?? const <Shoe>[];
    final shelfItems =
        ref.read(shelfItemsProvider(shelfId)).value ?? const <ShelfItem>[];
    final placedIds = shelfItems.map((item) => item.shoeId).toSet();
    final availableShoes =
        allShoes.where((shoe) => !placedIds.contains(shoe.id)).toList();
    final brands = ref.read(brandsProvider).value ?? const <Brand>[];
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };

    final selected = await showModalBottomSheet<Shoe>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: availableShoes.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('追加できる靴がありません（すべて棚に置かれています）'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableShoes.length,
                itemBuilder: (context, index) {
                  final shoe = availableShoes[index];
                  return ListTile(
                    title: Text(
                      shoe.displayTitle?.isNotEmpty == true
                          ? shoe.displayTitle!
                          : shoe.modelName,
                    ),
                    subtitle: Text(brandNames[shoe.brandId] ?? ''),
                    onTap: () => Navigator.pop(ctx, shoe),
                  );
                },
              ),
      ),
    );
    if (selected == null || selected.id == null || !mounted) return;

    final result = await ref
        .read(shelfRepositoryProvider)
        .addShoeToShelf(shelfId, selected.id!);
    if (result == null) {
      if (mounted) {
        await showAppMessage(
          context,
          title: '棚がいっぱいです',
          message: '棚には25足まで置けます。',
        );
      }
      return;
    }
    ref.invalidate(shelfItemsProvider(shelfId));
  }
}

class _CollectionContent extends ConsumerWidget {
  final List<Shoe> shoes;
  final List<Shelf> shelves;
  final PageController pageController;
  final GlobalKey Function(int shelfId) shareKeyFor;
  final ValueChanged<int> onPageChanged;
  final bool isDragging;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final List<Brand> brands;
  final int? selectedBrandId;
  final String? selectedStatus;
  final String? selectedColor;
  final String searchText;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onBrandSelected;
  final ValueChanged<String?> onStatusSelected;
  final ValueChanged<String?> onColorSelected;

  const _CollectionContent({
    required this.shoes,
    required this.shelves,
    required this.pageController,
    required this.shareKeyFor,
    required this.onPageChanged,
    required this.isDragging,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.brands,
    required this.selectedBrandId,
    required this.selectedStatus,
    required this.selectedColor,
    required this.searchText,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBrandSelected,
    required this.onStatusSelected,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(collectionColumnsProvider).value ?? 2;
    final columnsNotifier = ref.read(collectionColumnsProvider.notifier);
    final brandNames = {
      for (final brand in brands)
        if (brand.id != null) brand.id!: brand.name,
    };
    final filteredShoes = _filterShoes(brandNames);
    final savedColors = shoes
        .expand((shoe) => (shoe.color ?? '').split(','))
        .map((color) => color.trim())
        .where((color) => color.isNotEmpty);
    final colors = <String>{
      ..._collectionColorOptions.map((option) => option.$1),
      ...savedColors,
    }.toList();
    final activeFilterCount = [selectedStatus, selectedBrandId, selectedColor]
        .where((value) => value != null)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'モデル名で検索',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchText.isNotEmpty)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '検索をクリア',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.zoom_in, size: 19),
                    tooltip: '大きく表示',
                    onPressed: columns == 2
                        ? null
                        : () => columnsNotifier.setColumns(columns - 1),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.zoom_out, size: 19),
                    tooltip: '小さく表示',
                    onPressed: columns == 5
                        ? null
                        : () => columnsNotifier.setColumns(columns + 1),
                  ),
                  Badge(
                    isLabelVisible: activeFilterCount > 0,
                    label: Text('$activeFilterCount'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 34, height: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.tune, size: 19),
                      tooltip: '絞り込み',
                      onPressed: () => _showFilters(context, colors),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: isDragging
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: onPageChanged,
            itemCount: shelves.length,
            itemBuilder: (context, index) {
              final shelf = shelves[index];
              return RepaintBoundary(
                key: shareKeyFor(shelf.id),
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final shelfItemsAsync =
                          ref.watch(shelfItemsProvider(shelf.id));
                      return shelfItemsAsync.when(
                        data: (shelfItems) => _ShelfGrid(
                          shelfId: shelf.id,
                          shelfItems: shelfItems,
                          filteredShoes: filteredShoes,
                          allShoes: shoes,
                          brandNames: brandNames,
                          onDragStarted: onDragStarted,
                          onDragEnd: onDragEnd,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                            const Center(child: Text('棚を読み込めませんでした')),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Shoe> _filterShoes(Map<int, String> brandNames) {
    final query = searchText.trim().toLowerCase();

    return shoes.where((shoe) {
      final matchesBrand =
          selectedBrandId == null || shoe.brandId == selectedBrandId;
      final matchesStatus =
          selectedStatus == null || shoe.status == selectedStatus;
      final matchesColor = selectedColor == null ||
          (shoe.color ?? '')
              .split(',')
              .map((color) => color.trim())
              .contains(selectedColor);
      final brandName = brandNames[shoe.brandId] ?? '';
      final matchesSearch = query.isEmpty ||
          shoe.modelName.toLowerCase().contains(query) ||
          brandName.toLowerCase().contains(query) ||
          (shoe.displayTitle?.toLowerCase().contains(query) ?? false) ||
          (shoe.stickerText?.toLowerCase().contains(query) ?? false);

      return matchesBrand && matchesStatus && matchesColor && matchesSearch;
    }).toList();
  }

  Future<void> _showFilters(BuildContext context, List<String> colors) async {
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
                      onStatusSelected(null);
                      onBrandSelected(null);
                      onColorSelected(null);
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('すべて解除'),
                  ),
                ],
              ),
              _FilterGroup(
                label: '状態',
                children: [
                  _sheetChip(sheetContext, 'すべて', selectedStatus == null,
                      () => onStatusSelected(null)),
                  ...const [
                    (value: Shoe.statusNew, label: '新品'),
                    (value: Shoe.statusWorn, label: '着用済み'),
                    (value: Shoe.statusParted, label: '手放した'),
                  ].map((status) => _sheetChip(
                        sheetContext,
                        status.label,
                        selectedStatus == status.value,
                        () => onStatusSelected(status.value),
                      )),
                ],
              ),
              _FilterGroup(
                label: 'ブランド',
                children: [
                  _sheetChip(sheetContext, 'すべて', selectedBrandId == null,
                      () => onBrandSelected(null)),
                  ...brands.map((brand) => _sheetChip(
                        sheetContext,
                        brand.name,
                        selectedBrandId == brand.id,
                        () => onBrandSelected(brand.id),
                      )),
                ],
              ),
              if (colors.isNotEmpty)
                _FilterGroup(
                  label: 'カラー',
                  children: [
                    _sheetChip(sheetContext, 'すべて', selectedColor == null,
                        () => onColorSelected(null)),
                    ...colors.map((color) => _sheetChip(
                          sheetContext,
                          color,
                          selectedColor == color,
                          () => onColorSelected(color),
                          avatar: _colorAvatar(color),
                        )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetChip(
    BuildContext sheetContext,
    String label,
    bool selected,
    VoidCallback onSelected,
    {Widget? avatar}
  ) {
    return ChoiceChip(
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
        Navigator.pop(sheetContext);
      },
    );
  }

  Widget _colorAvatar(String label) {
    Color? color;
    for (final option in _collectionColorOptions) {
      if (option.$1 == label) {
        color = option.$2;
        break;
      }
    }
    if (color == null) {
      return const Icon(Icons.palette_outlined, size: 16);
    }
    return CircleAvatar(
      radius: 8,
      backgroundColor: color,
      child: color == Colors.white
          ? const Icon(Icons.circle_outlined, size: 14)
          : null,
    );
  }

}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

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

class _ShelfGrid extends ConsumerWidget {
  final int shelfId;
  final List<ShelfItem> shelfItems;
  final List<Shoe> filteredShoes;
  final List<Shoe> allShoes;
  final Map<int, String> brandNames;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  const _ShelfGrid({
    required this.shelfId,
    required this.shelfItems,
    required this.filteredShoes,
    required this.allShoes,
    required this.brandNames,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  double _gridSpacing(int columns) {
    switch (columns) {
      case 2:
        return 12;
      case 3:
        return 10;
      case 4:
        return 8;
      case 5:
        return 6;
      default:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(collectionColumnsProvider).value ?? 2;
    final filteredIds = filteredShoes.map((shoe) => shoe.id).toSet();
    final shoesById = {for (final shoe in allShoes) shoe.id: shoe};
    final slotToShoeId = {
      for (final item in shelfItems) item.slotIndex: item.shoeId,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Text(
                '${shelfItems.length}/${ShelfRepository.slotCount}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = 24.0;
              final spacing = _gridSpacing(columns);
              final cardWidth =
                  (constraints.maxWidth -
                      horizontalPadding -
                      spacing * (columns - 1)) /
                  columns;
              final compact = cardWidth < 130;
              final tiny = cardWidth < 90;
              final imageHeight = cardWidth * 0.82;
              final titleHeight = tiny
                  ? 50.0
                  : compact
                      ? 68.0
                      : 116.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _ShelfBackdrop(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: imageHeight + titleHeight,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: ShelfRepository.slotCount,
                      itemBuilder: (context, slotIndex) {
                        final shoeId = slotToShoeId[slotIndex];
                        final shoe = (shoeId != null && filteredIds.contains(shoeId))
                            ? shoesById[shoeId]
                            : null;
                        return _ShelfSlot(
                          shelfId: shelfId,
                          slotIndex: slotIndex,
                          shoe: shoe,
                          brandNames: brandNames,
                          onDragStarted: onDragStarted,
                          onDragEnd: onDragEnd,
                        );
                      },
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

/// 棚の見た目（背景・枠）を配置ロジックから独立させたウィジェット。
/// 将来のテーマ機能（背景画像選択）はここだけを差し替えれば対応できる。
/// 固定のheightを指定しないため、列数変更でchildの高さが変わっても追従する。
class _ShelfBackdrop extends StatelessWidget {
  const _ShelfBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E7D3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ShelfSlot extends ConsumerWidget {
  const _ShelfSlot({
    required this.shelfId,
    required this.slotIndex,
    required this.shoe,
    required this.brandNames,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final int shelfId;
  final int slotIndex;
  final Shoe? shoe;
  final Map<int, String> brandNames;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != shoe?.id,
      onAcceptWithDetails: (details) async {
        await ref
            .read(shelfRepositoryProvider)
            .moveShoeSlot(shelfId, details.data, slotIndex);
        ref.invalidate(shelfItemsProvider(shelfId));
      },
      builder: (context, candidateData, rejectedData) {
        final shoe = this.shoe;
        if (shoe == null) {
          return _EmptySlot(highlighted: candidateData.isNotEmpty);
        }

        final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
        final imagePath = mainPhotoAsync.maybeWhen(
          data: (photo) => photo?.cutoutPath ?? photo?.filePath,
          orElse: () => null,
        );
        final card = ShoeCard(
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
          modelName: shoe.displayTitle?.isNotEmpty == true
              ? shoe.displayTitle!
              : shoe.modelName,
          size: shoe.size ?? '-',
          color: shoe.color ?? '',
          statusLabel: shoe.statusLabel,
          imagePath: imagePath,
          archiveNumber: null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
              ),
            );
          },
        );

        return LongPressDraggable<int>(
          data: shoe.id!,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 130, height: 170, child: card),
          ),
          childWhenDragging: const _EmptySlot(highlighted: false),
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnd(),
          child: card,
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? colors.primary : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
