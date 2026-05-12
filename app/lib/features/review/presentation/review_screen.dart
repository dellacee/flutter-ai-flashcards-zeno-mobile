import 'package:flutter/material.dart';
import 'package:zeno/core/widgets/empty_state.dart';

/// Placeholder review screen shown on the Review tab.
class ReviewScreen extends StatelessWidget {
  /// Creates a [ReviewScreen].
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: const EmptyState(
        icon: Icons.psychology_outlined,
        title: 'Nothing to review',
        description:
            'Add cards to a deck and they will queue up here automatically.',
      ),
    );
  }
}
