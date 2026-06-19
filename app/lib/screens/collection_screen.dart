import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import '../widgets/shoe_card.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shoes = <Map<String, String>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: shoes.isEmpty
          ? EmptyState(
              icon: Icons.collections_outlined,
              title: 'No shoes yet',
              description: 'Add your first shoe by tapping the + button below.',
              actionLabel: 'Add Shoe',
              onAction: () {
                // TODO: Navigate to add shoe screen
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: shoes.length,
              itemBuilder: (context, index) {
                final shoe = shoes[index];
                return ShoeCard(
                  brandName: shoe['brand'] ?? '',
                  modelName: shoe['model'] ?? '',
                  size: shoe['size'] ?? '',
                  color: shoe['color'] ?? '',
                  onTap: () {
                    // TODO: Navigate to shoe detail
                  },
                  onFavoriteTap: () {
                    // TODO: Toggle favorite
                  },
                );
              },
            ),
    );
  }
}
