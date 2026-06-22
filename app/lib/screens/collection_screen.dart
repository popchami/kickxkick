import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoesAsync = ref.watch(shoesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('コレクション'),
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
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              onBrandSelected: (brandId) {
                setState(() {
                  _selectedBrandId = brandId;
                });
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _CollectionContent(
              shoes: shoes,
              brands: const [],
              selectedBrandId: _selectedBrandId,
              searchText: _searchText,
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              onBrandSelected: (brandId) {
                setState(() {
                  _selectedBrandId = brandId;
                });
              },
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
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onBrandSelected;

  const _CollectionContent({
    required this.shoes,
    required this.brands,
    required this.selectedBrandId,
    required this.searchText,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBrandSelected,
  });

  @override
  Widget build(BuildContext context) {
    final brandNames = {
      for (final brand in brands) if (brand.id != null) brand.id!: brand.name,
    };
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
        if (brands.isNotEmpty)
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
                    selected: selectedBrandId == null,
                    onSelected: (_) => onBrandSelected(null),
                  ),
                ),
                ...brands.map(
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

    return shoes.where((shoe) {
      final matchesBrand = selectedBrandId == null || shoe.brandId == selectedBrandId;
      final brandName = brandNames[shoe.brandId] ?? '';
      final matchesSearch = query.isEmpty ||
          shoe.modelName.toLowerCase().contains(query) ||
          brandName.toLowerCase().contains(query);

      return matchesBrand && matchesSearch;
    }).toList();
  }
}

class _ShoeGrid extends ConsumerWidget {
  final List<Shoe> shoes;
  final Map<int, String> brandNames;

  const _ShoeGrid({required this.shoes, required this.brandNames});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        return ShoeCard(
          brandName: brandNames[shoe.brandId] ?? 'Unknown',
          modelName: shoe.modelName,
          size: shoe.size ?? '-',
          color: shoe.color ?? '',
          isFavorite: shoe.isFavorite,
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
