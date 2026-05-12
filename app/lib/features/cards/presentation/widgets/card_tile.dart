import 'package:flutter/material.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';

/// Regex that matches a cloze marker and captures the hidden word.
final _clozeDisplayRegex = RegExp(r'\{\{c\d+::([^}]+)\}\}');

/// A single list-item showing a preview of the given flash card.
///
/// Type-aware: QaCard shows front/back; ClozeCard shows cloze text with
/// markers replaced by bracketed words; McqCard shows question + option count.
///
/// Wrapped in a Dismissible — swiping end-to-start shows a red background
/// and triggers a confirm dialog before calling [onDelete].
///
/// Design choice: NOT wrapped in a Card widget. The parent list uses
/// ListView.separated with Dividers.
class CardTile extends StatelessWidget {
  const CardTile({
    required this.card,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final FlashCard card;
  final VoidCallback onTap;

  /// Called after the user confirms deletion. The caller deletes from repo.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = _tileData(card);

    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns (icon, title, subtitle?) for the given [FlashCard] variant.
  static (IconData, String, String?) _tileData(FlashCard card) {
    return switch (card) {
      QaCard(:final front, :final back) => (
        Icons.help_outline,
        front,
        back,
      ),
      ClozeCard(:final text) => (
        Icons.short_text,
        text.replaceAllMapped(_clozeDisplayRegex, (m) => '[${m.group(1)}]'),
        null,
      ),
      McqCard(:final question, :final options) => (
        Icons.checklist,
        question,
        '${options.length} lựa chọn',
      ),
    };
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa card này?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            'Xóa',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }
}
