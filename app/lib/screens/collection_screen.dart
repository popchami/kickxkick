import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/collection_filter_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/settings_provider.dart';
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
  final _searchController = TextEditingController();
  final _shareKey = GlobalKey();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final collectionFilter = ref.watch(collectionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('コレクション'),
        actions: [
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

          return brandsAsync.when(
            data: (brands) => _CollectionContent(
              shoes: shoes,
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
              shareKey: _shareKey,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _CollectionContent(
              shoes: shoes,
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
              shareKey: _shareKey,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }

  Future<void> _shareCollection() async {
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
}

class _CollectionContent extends ConsumerWidget {
  final List<Shoe> shoes;
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
  final GlobalKey shareKey;

  const _CollectionContent({
    required this.shoes,
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
    required this.shareKey,
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
          child: RepaintBoundary(
            key: shareKey,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: filteredShoes.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_outlined,
                      title: '該当するスニーカーがありません',
                      description: '検索条件を変更してください',
                    )
                  : _ShoeGrid(shoes: filteredShoes, brandNames: brandNames),
            ),
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

class _ShoeGrid extends ConsumerWidget {
  final List<Shoe> shoes;
  final Map<int, String> brandNames;

  const _ShoeGrid({required this.shoes, required this.brandNames});

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Text(
                '${shoes.length}/25',
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

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: imageHeight + titleHeight,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                ),
                itemCount: shoes.length,
                itemBuilder: (context, index) {
                  final shoe = shoes[index];
                  final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
                  final imagePath = mainPhotoAsync.maybeWhen(
                    data: (photo) => photo?.cutoutPath ?? photo?.filePath,
                    orElse: () => null,
                  );

                  return ShoeCard(
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
