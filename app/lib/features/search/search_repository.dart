import 'package:flutter/services.dart' show rootBundle;

import 'search_index.dart';

class SearchRepository {
  const SearchRepository();

  static const String _brandsPath = 'assets/data/brands.json';
  static const String _modelsPath = 'assets/data/models.json';
  static const String _aliasesPath = 'assets/data/aliases.json';
  static const String _searchKeywordsPath = 'assets/data/search_keywords.json';

  Future<SearchIndex> loadIndex() async {
    final results = await Future.wait<String>([
      rootBundle.loadString(_brandsPath),
      rootBundle.loadString(_modelsPath),
      rootBundle.loadString(_aliasesPath),
      rootBundle.loadString(_searchKeywordsPath),
    ]);

    return SearchIndex.fromJsonStrings(
      brandsJson: results[0],
      modelsJson: results[1],
      aliasesJson: results[2],
      searchKeywordsJson: results[3],
    );
  }
}
