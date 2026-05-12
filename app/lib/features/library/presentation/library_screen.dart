import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/core/widgets/loading_skeleton.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';
import 'package:zeno/features/library/presentation/widgets/deck_card.dart';

/// The Library tab screen that lists all decks for the signed-in user.
///
/// Watches [deckListProvider] and renders a [ListView] of [DeckCard]s,
/// a loading skeleton while data is being fetched, or an error/empty state.
class LibraryScreen extends ConsumerWidget {
  /// Creates a [LibraryScreen].
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckListAsync = ref.watch(deckListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/decks/new'),
        icon: const Icon(Icons.add),
        label: const Text('New deck'),
      ),
      body: deckListAsync.when(
        data: (decks) {
          if (decks.isEmpty) {
            return const EmptyState(
              icon: Icons.library_books_outlined,
              title: 'No decks yet',
              description: 'Tạo deck đầu tiên để bắt đầu học.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return DeckCard(
                deck: deck,
                onTap: () => context.push('/decks/${deck.id}'),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const LoadingSkeleton(height: 96),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Có lỗi',
          description: e.toString(),
        ),
      ),
    );
  }
}
