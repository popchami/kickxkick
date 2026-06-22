import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/photo_storage_service.dart';

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});
