import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/shelf_repository.dart';

final shelfRepositoryProvider = Provider((ref) => ShelfRepository());
