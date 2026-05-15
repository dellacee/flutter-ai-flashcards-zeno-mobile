import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/review/domain/review_rating.dart';
import 'package:zeno/features/review/presentation/providers/review_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  bool _flipped = false;
  bool _submitting = false;
  int? _selectedMcqOption;
  bool _done = false;

  void _flip() {
    setState(() => _flipped = !_flipped);
  }

  Future<void> _rate(List<FlashCard> queue, ReviewRating rating) async {
    if (_submitting) return;
    final card = queue[_index];
    setState(() => _submitting = true);
    try {
      await ref.read(cardRepositoryProvider).submitReview(
            deckId: card.deckId,
            cardId: card.id,
            rating: rating,
            reviewedAt: DateTime.now(),
          );
    } finally {
      if (mounted) {
        final nextIndex = _index + 1;
        if (nextIndex >= queue.length) {
          setState(() {
            _done = true;
            _submitting = false;
          });
          ref.invalidate(dueCardsAllProvider);
        } else {
          setState(() {
            _index = nextIndex;
            _flipped = false;
            _selectedMcqOption = null;
            _submitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncQueue = ref.watch(dueCardsAllProvider);

    return Scaffold(
      appBar: AppBar(
        title: asyncQueue.maybeWhen(
          data: (queue) => queue.isEmpty
              ? const Text('Review')
              : Text('${_done ? queue.length : _index + 1} / ${queue.length}'),
          orElse: () => const Text('Review'),
        ),
      ),
      body: asyncQueue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Không thể load',
          description: e.toString(),
        ),
        data: (queue) {
          if (queue.isEmpty) {
            return const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Không có card đến hạn',
              description: 'Tạo deck mới hoặc đợi tới hạn.',
            );
          }

          if (_done) {
            return const EmptyState(
              icon: Icons.celebration_outlined,
              title: '🎉 Hôm nay xong!',
              description: 'Quay lại ngày mai.',
            );
          }

          final card = queue[_index];
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _flip,
                    child: _CardFace(
                      card: card,
                      flipped: _flipped,
                      selectedMcqOption: _selectedMcqOption,
                      onMcqOptionSelected: (i) {
                        setState(() {
                          _selectedMcqOption = i;
                          _flipped = true;
                        });
                      },
                    ).animate(key: ValueKey(_index)).fadeIn(duration: 200.ms),
                  ),
                ),
              ),
              if (_flipped || card is McqCard && _selectedMcqOption != null)
                _RatingBar(
                  submitting: _submitting,
                  onRate: (r) => _rate(queue, r),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card face widget
// ---------------------------------------------------------------------------

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.flipped,
    required this.selectedMcqOption,
    required this.onMcqOptionSelected,
  });

  final FlashCard card;
  final bool flipped;
  final int? selectedMcqOption;
  final ValueChanged<int> onMcqOptionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (card) {
          QaCard() => _QaFace(
              card: card as QaCard,
              flipped: flipped,
              theme: theme,
            ),
          ClozeCard() => _ClozeFace(
              card: card as ClozeCard,
              flipped: flipped,
              theme: theme,
            ),
          McqCard() => _McqFace(
              card: card as McqCard,
              selectedOption: selectedMcqOption,
              onOptionSelected: onMcqOptionSelected,
              theme: theme,
            ),
        },
      ),
    );
  }
}

class _QaFace extends StatelessWidget {
  const _QaFace({
    required this.card,
    required this.flipped,
    required this.theme,
  });

  final QaCard card;
  final bool flipped;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            flipped ? 'Câu trả lời' : 'Câu hỏi',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            flipped ? card.back : card.front,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (!flipped) ...[
            const SizedBox(height: 24),
            Text(
              'Nhấn để lật',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

String _renderCloze(String text, {required bool revealed}) {
  final pattern = RegExp(r'\{\{c\d+::([^}]+)\}\}');
  if (revealed) {
    return text.replaceAllMapped(pattern, (m) => '[${m.group(1)}]');
  }
  return text.replaceAll(pattern, '___');
}

class _ClozeFace extends StatelessWidget {
  const _ClozeFace({
    required this.card,
    required this.flipped,
    required this.theme,
  });

  final ClozeCard card;
  final bool flipped;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            flipped ? 'Đáp án' : 'Điền vào chỗ trống',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _renderCloze(card.text, revealed: flipped),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (!flipped) ...[
            const SizedBox(height: 24),
            Text(
              'Nhấn để xem đáp án',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _McqFace extends StatelessWidget {
  const _McqFace({
    required this.card,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.theme,
  });

  final McqCard card;
  final int? selectedOption;
  final ValueChanged<int> onOptionSelected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            card.question,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...card.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = selectedOption == i;
            final isCorrect = i == card.correctIndex;
            final revealed = selectedOption != null;

            Color? bgColor;
            if (revealed) {
              if (isCorrect) {
                bgColor = Colors.green.withAlpha(38);
              } else if (isSelected) {
                bgColor = Colors.red.withAlpha(38);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: revealed ? null : () => onOptionSelected(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor ?? theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: revealed && isCorrect
                          ? Colors.green
                          : revealed && isSelected
                              ? Colors.red
                              : theme.colorScheme.outline.withAlpha(77),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(option, style: theme.textTheme.bodyLarge),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating bar
// ---------------------------------------------------------------------------

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.submitting,
    required this.onRate,
  });

  final bool submitting;
  final ValueChanged<ReviewRating> onRate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _RatingButton(
              label: 'Lại',
              color: Colors.red,
              rating: ReviewRating.again,
              submitting: submitting,
              onTap: onRate,
            ),
            const SizedBox(width: 6),
            _RatingButton(
              label: 'Khó',
              color: Colors.orange,
              rating: ReviewRating.hard,
              submitting: submitting,
              onTap: onRate,
            ),
            const SizedBox(width: 6),
            _RatingButton(
              label: 'Tốt',
              color: Colors.green,
              rating: ReviewRating.good,
              submitting: submitting,
              onTap: onRate,
            ),
            const SizedBox(width: 6),
            _RatingButton(
              label: 'Dễ',
              color: Colors.blue,
              rating: ReviewRating.easy,
              submitting: submitting,
              onTap: onRate,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.rating,
    required this.submitting,
    required this.onTap,
  });

  final String label;
  final Color color;
  final ReviewRating rating;
  final bool submitting;
  final ValueChanged<ReviewRating> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: color.withAlpha(31),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: submitting ? null : () => onTap(rating),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
