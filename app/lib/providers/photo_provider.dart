import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/photo.dart';
import '../repositories/photo_repository.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository();
});

final photosByShoeIdProvider = FutureProvider.family<List<Photo>, int>((ref, shoeId) async {
  final repository = ref.watch(photoRepositoryProvider);
  return repository.getPhotosByShoeId(shoeId);
});

final mainPhotoProvider = FutureProvider.family<Photo?, int>((ref, shoeId) async {
  final repository = ref.watch(photoRepositoryProvider);
  return repository.getMainPhoto(shoeId);
});
