import 'package:flutter/material.dart';
import 'package:zeno/features/library/domain/deck.dart';

/// A list-item card that displays a single [Deck].
///
/// Shows the deck title, optional description, card count, and a
/// "due" pill when [Deck.dueCount] is greater than zero.
class DeckCard extends StatelessWidget {
  /// Creates a [DeckCard].
  const DeckCard({required this.deck, super.key, this.onTap});

  /// The deck to display.
  final Deck deck;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                deck.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Optional description
              if (deck.description != null && deck.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  deck.description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Footer row: card count + due pill
              Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${deck.cardCount} cards',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (deck.dueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${deck.dueCount} due',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
