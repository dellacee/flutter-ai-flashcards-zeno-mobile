import 'package:flutter/material.dart';
import 'package:zeno/core/widgets/empty_state.dart';

/// Placeholder home screen shown on the Home tab.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const EmptyState(
        icon: Icons.dashboard_outlined,
        title: 'Welcome to Zeno',
        description: 'Your daily review will appear here once you '
            'create your first deck.',
      ),
    );
  }
}
