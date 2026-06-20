import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shoe.dart';
import '../repositories/shoe_repository.dart';

final shoeRepositoryProvider = Provider<ShoeRepository>((ref) {
  return ShoeRepository();
});

final shoesProvider = FutureProvider<List<Shoe>>((ref) async {
  final repository = ref.watch(shoeRepositoryProvider);
  return repository.getAllShoes();
});

final shoeByIdProvider = FutureProvider.family<Shoe?, int>((ref, id) async {
  final repository = ref.watch(shoeRepositoryProvider);
  return repository.getShoeById(id);
});
