import 'dart:convert';

import 'search_models.dart';
import 'search_normalizer.dart';

class SearchIndex {
  SearchIndex({
    required this.brands,
    required this.models,
    required this.aliases,
    required this.keywords,
    SearchNormalizer normalizer = const SearchNormalizer(),
  }) : _normalizer = normalizer {
    _modelsById = {for (final model in models) model.id: model};
    _modelsByBrandId = <String, List<SneakerModelMaster>>{};

    for (final model in models) {
      _modelsByBrandId.putIfAbsent(model.brandId, () => []).add(model);
    }

    for (final entry in _modelsByBrandId.entries) {
      entry.value.sort((a, b) => a.modelName.compareTo(b.modelName));
    }

    _aliasesByModelId = <String, List<ModelAliasMaster>>{};
    for (final alias in aliases) {
      _aliasesByModelId.putIfAbsent(alias.modelId, () => []).add(alias);
    }

    _keywordsByModelId = <String, List<SearchKeywordMaster>>{};
    for (final keyword in keywords) {
      _keywordsByModelId.putIfAbsent(keyword.modelId, () => []).add(keyword);
    }
  }

  final List<BrandMaster> brands;
  final List<SneakerModelMaster> models;
  final List<ModelAliasMaster> aliases;
  final List<SearchKeywordMaster> keywords;
  final SearchNormalizer _normalizer;

  late final Map<String, SneakerModelMaster> _modelsById;
  late final Map<String, List<SneakerModelMaster>> _modelsByBrandId;
  late final Map<String, List<ModelAliasMaster>> _aliasesByModelId;
  late final Map<String, List<SearchKeywordMaster>> _keywordsByModelId;

  static SearchIndex fromJsonStrings({
    required String brandsJson,
    required String modelsJson,
    required String aliasesJson,
    required String searchKeywordsJson,
  }) {
    final brandsRoot = jsonDecode(brandsJson) as Map<String, dynamic>;
    final modelsRoot = jsonDecode(modelsJson) as Map<String, dynamic>;
    final aliasesRoot = jsonDecode(aliasesJson) as Map<String, dynamic>;
    final keywordsRoot = jsonDecode(searchKeywordsJson) as Map<String, dynamic>;

    return SearchIndex(
      brands: (brandsRoot['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BrandMaster.fromJson)
          .toList(),
      models: (modelsRoot['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(SneakerModelMaster.fromJson)
          .toList(),
      aliases: (aliasesRoot['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ModelAliasMaster.fromJson)
          .toList(),
      keywords: (keywordsRoot['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(SearchKeywordMaster.fromJson)
          .toList(),
    );
  }

  List<SneakerModelMaster> modelsForBrand(String brandId) {
    return List.unmodifiable(_modelsByBrandId[brandId] ?? const []);
  }

  SneakerModelMaster? modelById(String modelId) => _modelsById[modelId];

  List<ModelAliasMaster> aliasesForModel(String modelId) {
    return List.unmodifiable(_aliasesByModelId[modelId] ?? const []);
  }

  List<SearchKeywordMaster> keywordsForModel(String modelId) {
    return List.unmodifiable(_keywordsByModelId[modelId] ?? const []);
  }

  String normalize(String input) => _normalizer.normalize(input);
}
