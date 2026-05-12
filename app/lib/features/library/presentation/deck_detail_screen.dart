import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';

/// Screen displaying full details for a single deck.
///
/// Watches [deckByIdProvider] and renders stats, tags, and a sources
/// placeholder. The AppBar popup menu exposes "Sửa" and "Xóa" actions.
class DeckDetailScreen extends ConsumerWidget {
  /// Creates a [DeckDetailScreen].
  const DeckDetailScreen({required this.deckId, super.key});

  /// The Firestore document id for the deck to display.
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));

    final title = deckAsync.valueOrNull?.title ?? 'Loading…';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _PopupMenu(deckId: deckId, deckAsync: deckAsync),
        ],
      ),
      body: deckAsync.when(
        data: (deck) => _DeckDetailBody(deck: deck),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Không tìm thấy deck',
          description: e.toString(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popup menu — separated to keep the main widget clean
// ---------------------------------------------------------------------------

class _PopupMenu extends ConsumerWidget {
  const _PopupMenu({required this.deckId, required this.deckAsync});

  final String deckId;
  final AsyncValue<Deck> deckAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_DeckAction>(
      onSelected: (action) async {
        switch (action) {
          case _DeckAction.edit:
            await context.push('/decks/$deckId/edit');
          case _DeckAction.delete:
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Xóa deck?'),
                content: const Text(
                  'Hành động này không thể hoàn tác. Tất cả thẻ trong deck '
                  'cũng sẽ bị xóa.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(ctx).colorScheme.error,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await ref.read(deckRepositoryProvider).deleteDeck(deckId);
              if (context.mounted) context.go('/library');
            }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _DeckAction.edit,
          child: Text('Sửa'),
        ),
        PopupMenuItem(
          value: _DeckAction.delete,
          child: Text('Xóa'),
        ),
      ],
    );
  }
}

enum _DeckAction { edit, delete }

// ---------------------------------------------------------------------------
// Body — renders when data is loaded
// ---------------------------------------------------------------------------

class _DeckDetailBody extends StatelessWidget {
  const _DeckDetailBody({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (deck.description != null && deck.description!.isNotEmpty)
            Text(
              deck.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 16),

          // Tag chips
          if (deck.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: deck.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Cards',
                  value: deck.cardCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Due',
                  value: deck.dueCount.toString(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sources section
          Text('Sources', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Chưa có nguồn nào — V1.1 sẽ bổ sung upload PDF/URL.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
