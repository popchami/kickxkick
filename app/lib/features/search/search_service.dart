import 'search_index.dart';
import 'search_models.dart';

class SearchService {
  const SearchService(this.index);

  final SearchIndex index;

  List<BrandSuggestion> suggestBrands(String query, {int limit = 5}) {
    final normalizedQuery = index.normalize(query);
    if (normalizedQuery.isEmpty) {
      return index.brands
          .where((brand) => brand.isEnabled)
          .take(limit)
          .map((brand) => BrandSuggestion(
                brand: brand,
                matchedText: brand.brandName,
              ))
          .toList();
    }

    final suggestions = <BrandSuggestion>[];

    for (final brand in index.brands.where((brand) => brand.isEnabled)) {
      final normalizedName = index.normalize(brand.brandName);
      final normalizedId = index.normalize(brand.brandId);

      if (normalizedName.startsWith(normalizedQuery) ||
          normalizedId.startsWith(normalizedQuery) ||
          normalizedName.contains(normalizedQuery)) {
        suggestions.add(BrandSuggestion(
          brand: brand,
          matchedText: brand.brandName,
        ));
      }
    }

    suggestions.sort((a, b) => a.brand.brandName.compareTo(b.brand.brandName));
    return suggestions.take(limit).toList();
  }

  List<ModelSuggestion> suggestModels({
    required String brandId,
    required String query,
    int limit = 5,
  }) {
    final normalizedQuery = index.normalize(query);
    final brandModels = index.modelsForBrand(brandId);

    if (normalizedQuery.isEmpty) {
      return brandModels
          .take(limit)
          .map((model) => ModelSuggestion(
                model: model,
                matchedBy: 'modelName',
                matchedText: model.modelName,
              ))
          .toList();
    }

    final exact = <ModelSuggestion>[];
    final startsWith = <ModelSuggestion>[];
    final contains = <ModelSuggestion>[];

    for (final model in brandModels) {
      final match = _matchModel(model, normalizedQuery);
      if (match == null) continue;

      switch (match.rank) {
        case _MatchRank.exact:
          exact.add(match.suggestion);
          break;
        case _MatchRank.startsWith:
          startsWith.add(match.suggestion);
          break;
        case _MatchRank.contains:
          contains.add(match.suggestion);
          break;
      }
    }

    int sortByName(ModelSuggestion a, ModelSuggestion b) {
      return a.model.modelName.compareTo(b.model.modelName);
    }

    exact.sort(sortByName);
    startsWith.sort(sortByName);
    contains.sort(sortByName);

    return [...exact, ...startsWith, ...contains].take(limit).toList();
  }

  _ModelMatch? _matchModel(
    SneakerModelMaster model,
    String normalizedQuery,
  ) {
    final normalizedModelName = index.normalize(model.modelName);

    final modelNameMatch = _rank(normalizedModelName, normalizedQuery);
    if (modelNameMatch != null) {
      return _ModelMatch(
        rank: modelNameMatch,
        suggestion: ModelSuggestion(
          model: model,
          matchedBy: 'modelName',
          matchedText: model.modelName,
        ),
      );
    }

    for (final alias in index.aliasesForModel(model.id)) {
      final normalizedAlias = index.normalize(alias.alias);
      final aliasMatch = _rank(normalizedAlias, normalizedQuery);
      if (aliasMatch != null) {
        return _ModelMatch(
          rank: aliasMatch,
          suggestion: ModelSuggestion(
            model: model,
            matchedBy: 'alias',
            matchedText: alias.alias,
          ),
        );
      }
    }

    for (final keyword in index.keywordsForModel(model.id)) {
      final normalizedKeyword = index.normalize(keyword.keyword);
      final keywordMatch = _rank(normalizedKeyword, normalizedQuery);
      if (keywordMatch != null) {
        return _ModelMatch(
          rank: keywordMatch,
          suggestion: ModelSuggestion(
            model: model,
            matchedBy: 'searchKeyword',
            matchedText: keyword.keyword,
          ),
        );
      }
    }

    return null;
  }

  _MatchRank? _rank(String candidate, String query) {
    if (candidate == query) return _MatchRank.exact;
    if (candidate.startsWith(query)) return _MatchRank.startsWith;
    if (candidate.contains(query)) return _MatchRank.contains;
    return null;
  }
}

class _ModelMatch {
  const _ModelMatch({
    required this.rank,
    required this.suggestion,
  });

  final _MatchRank rank;
  final ModelSuggestion suggestion;
}

enum _MatchRank { exact, startsWith, contains }
