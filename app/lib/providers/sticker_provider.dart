import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sticker_asset.dart';
import '../repositories/sticker_repository.dart';

final stickerRepositoryProvider = Provider((ref) => StickerRepository());

final stickersProvider = FutureProvider<List<StickerAsset>>((ref) {
  return ref.watch(stickerRepositoryProvider).getStickers();
});
