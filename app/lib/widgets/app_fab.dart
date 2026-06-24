import 'package:flutter/material.dart';

import '../screens/shoe_form_screen.dart';

class AppFab extends StatelessWidget {
  const AppFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      tooltip: 'スニーカーを追加',
      icon: const Icon(Icons.add),
      label: const Text(
        '追加',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
        );
      },
    );
  }
}
