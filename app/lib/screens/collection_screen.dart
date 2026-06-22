import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';

enum _SortOption { newest, oldest, brand, modelName, favoriteFirst }
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shoe_card.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchController = TextEditingController();
  int? _selectedBrandId;
  String _searchText = '';
  _SortOption _sortOption = _SortOption.newest;
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('並び替え', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            ..._SortOption.values.map(
              (option) => RadioListTile<_SortOption>(
                title: Text(_sortLabel(option)),
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_SortOption option) {
    switch (option) {
      case _SortOption.newest: return '新しい順';
      case _SortOption.oldest: return '古い順';
      case _SortOption.brand: return 'ブランド順';
      case _SortOption.modelName: return 'モデル名順';
      case _SortOption.favoriteFirst: return 'お気に入り優先';
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('コレクション'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: _sortOption != _SortOption.newest
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: '並び替え',
            onPressed: () => _showSortSheet(context),
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
              actionLabel: '最初の一足を登録',
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
              selectedBrandId: _selectedBrandId,
              searchText: _searchText,
              sortOption: _sortOption,
              showFavoritesOnly: _showFavoritesOnly,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _searchText = value),
              onBrandSelected: (brandId) => setState(() => _selectedBrandId = brandId),
              onFavoritesChanged: (value) => setState(() => _showFavoritesOnly = value),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _CollectionContent(
              shoes: shoes,
              brands: const [],
              selectedBrandId: _selectedBrandId,
              searchText: _searchText,
              sortOption: _sortOption,
              showFavoritesOnly: _showFavoritesOnly,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _searchText = value),
              onBrandSelected: (brandId) => setState(() => _selectedBrandId = brandId),
              onFavoritesChanged: (value) => setState(() => _showFavoritesOnly = value),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込みに失敗しました')),
      ),
    );
  }
}

class _CollectionContent extends StatelessWidget {
  final List<Shoe> shoes;
  final List<Brand> brands;
  final int? selectedBrandId;
  final String searchText;
  final _SortOption sortOption;
  final bool showFavoritesOnly;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onBrandSelected;
  final ValueChanged<bool> onFavoritesChanged;

  const _CollectionContent({
    required this.shoes,
    required this.brands,
    required this.selectedBrandId,
    required this.searchText,
    required this.sortOption,
    required this.showFavoritesOnly,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBrandSelected,
    required this.onFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brandNames = {
      for (final brand in brands) if (brand.id != null) brand.id!: brand.name,
    };
    final brandsWithShoes = brands
        .where((brand) => shoes.any((shoe) => shoe.brandId == brand.id))
        .toList();
    final filteredShoes = _filterShoes(brandNames);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'モデル名で検索',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('すべて'),
                  selected: selectedBrandId == null && !showFavoritesOnly,
                  onSelected: (_) {
                    onBrandSelected(null);
                    onFavoritesChanged(false);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    Icons.favorite,
                    size: 16,
                    color: showFavoritesOnly
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                  label: const Text('お気に入り'),
                  selected: showFavoritesOnly,
                  onSelected: (value) => onFavoritesChanged(value),
                ),
              ),
              ...brandsWithShoes.map(
                (brand) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(brand.name),
                    selected: selectedBrandId == brand.id,
                    onSelected: (_) => onBrandSelected(brand.id),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredShoes.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: '該当するスニーカーがありません',
                  description: '検索条件を変更してください',
                )
              : _ShoeGrid(shoes: filteredShoes, brandNames: brandNames),
        ),
      ],
    );
  }

  List<Shoe> _filterShoes(Map<int, String> brandNames) {
    final query = searchText.trim().toLowerCase();

    var result = shoes.where((shoe) {
      final matchesBrand = selectedBrandId == null || shoe.brandId == selectedBrandId;
      final matchesFavorite = !showFavoritesOnly || shoe.isFavorite;
      final brandName = brandNames[shoe.brandId] ?? '';
      final matchesSearch = query.isEmpty ||
          shoe.modelName.toLowerCase().contains(query) ||
          brandName.toLowerCase().contains(query);

      return matchesBrand && matchesFavorite && matchesSearch;
    }).toList();

    switch (sortOption) {
      case _SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOption.brand:
        result.sort((a, b) =>
            (brandNames[a.brandId] ?? '').compareTo(brandNames[b.brandId] ?? ''));
      case _SortOption.modelName:
        result.sort((a, b) => a.modelName.compareTo(b.modelName));
      case _SortOption.favoriteFirst:
        result.sort((a, b) {
          if (a.isFavorite == b.isFavorite) {
            return b.createdAt.compareTo(a.createdAt);
          }
          return a.isFavorite ? -1 : 1;
        });
    }

    return result;
  }
}

class _ShoeGrid extends ConsumerWidget {
  final List<Shoe> shoes;
  final Map<int, String> brandNames;

  const _ShoeGrid({required this.shoes, required this.brandNames});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossAxisCount = MediaQuery.of(context).size.width >= 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.57,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        final mainPhotoAsync = ref.watch(mainPhotoProvider(shoe.id!));
        final imagePath = mainPhotoAsync.maybeWhen(
          data: (photo) => photo?.filePath,
          orElse: () => null,
        );

        return ShoeCard(
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
          modelName: shoe.modelName,
          imagePath: imagePath,
          isFavorite: shoe.isFavorite,
          archiveNumber: shoe.archiveNumber,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id!),
              ),
            );
          },
          onFavoriteTap: () async {
            await ref.read(shoeRepositoryProvider).toggleFavorite(
                  shoe.id!,
                  !shoe.isFavorite,
                );
            ref.invalidate(shoesProvider);
          },
        );
      },
    );
  }
}
