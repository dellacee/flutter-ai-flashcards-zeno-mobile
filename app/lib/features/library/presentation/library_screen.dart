import 'package:flutter/material.dart';
import 'package:zeno/core/widgets/empty_state.dart';

/// Placeholder library screen shown on the Library tab.
class LibraryScreen extends StatelessWidget {
  /// Creates a [LibraryScreen].
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const EmptyState(
        icon: Icons.library_books_outlined,
        title: 'No decks yet',
        description: 'Tạo deck đầu tiên để bắt đầu học.',
      ),
    );
  }
}
