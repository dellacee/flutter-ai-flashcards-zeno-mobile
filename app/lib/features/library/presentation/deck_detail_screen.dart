import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/core/widgets/loading_skeleton.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/cards/presentation/widgets/card_tile.dart';
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

class _DeckDetailBody extends ConsumerWidget {
  const _DeckDetailBody({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final cardsAsync = ref.watch(cardListProvider(deck.id));

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

          // Cards section header
          Row(
            children: [
              Expanded(
                child: Text('Cards', style: textTheme.titleSmall),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    context.push('/decks/${deck.id}/cards/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm card'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cards list driven by cardListProvider
          cardsAsync.when(
            data: (cards) {
              if (cards.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Chưa có card nào. Bấm 'Thêm card' để bắt đầu.",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return CardTile(
                    card: card,
                    onTap: () => context.push(
                      '/decks/${deck.id}/cards/${card.id}/edit',
                    ),
                    onDelete: () async {
                      await ref
                          .read(cardRepositoryProvider)
                          .deleteCard(
                            deckId: deck.id,
                            cardId: card.id,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa card')),
                        );
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Column(
              children: [
                LoadingSkeleton(height: 72),
                SizedBox(height: 8),
                LoadingSkeleton(height: 72),
                SizedBox(height: 8),
                LoadingSkeleton(height: 72),
              ],
            ),
            error: (e, _) => Text(
              'Lỗi tải cards: $e',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
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
