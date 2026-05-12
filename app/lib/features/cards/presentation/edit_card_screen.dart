import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/cards/presentation/widgets/cloze_card_form.dart';
import 'package:zeno/features/cards/presentation/widgets/mcq_card_form.dart';
import 'package:zeno/features/cards/presentation/widgets/qa_card_form.dart';

/// Screen for editing an existing flash card.
///
/// Unlike AddCardScreen the type is fixed — there is no SegmentedButton.
/// The correct form variant is chosen from the loaded card and pre-filled.
class EditCardScreen extends ConsumerStatefulWidget {
  const EditCardScreen({
    required this.deckId,
    required this.cardId,
    super.key,
  });

  final String deckId;
  final String cardId;

  @override
  ConsumerState<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends ConsumerState<EditCardScreen> {
  // QA
  String? _qaFront;
  String? _qaBack;
  bool _qaValid = true; // pre-filled → start valid

  // Cloze
  String? _clozeText;
  bool _clozeValid = true;

  // MCQ
  String? _mcqQuestion;
  List<String>? _mcqOptions;
  int? _mcqCorrectIndex;
  bool _mcqValid = true;

  bool _submitting = false;

  bool _currentValid(FlashCard card) => switch (card) {
    QaCard() => _qaValid,
    ClozeCard() => _clozeValid,
    McqCard() => _mcqValid,
  };

  Future<void> _save(FlashCard card) async {
    if (!_currentValid(card) || _submitting) return;
    setState(() => _submitting = true);

    final FlashCard updated;
    switch (card) {
      case QaCard(:final front, :final back):
        // card is narrowed to QaCard inside this case branch — no cast needed.
        updated = card.copyWith(
          front: (_qaFront ?? front).trim(),
          back: (_qaBack ?? back).trim(),
        );
      case ClozeCard(:final text):
        updated = card.copyWith(
          text: (_clozeText ?? text).trim(),
        );
      case McqCard(:final question, :final options, :final correctIndex):
        updated = card.copyWith(
          question: (_mcqQuestion ?? question).trim(),
          options: _mcqOptions ?? options,
          correctIndex: _mcqCorrectIndex ?? correctIndex,
        );
    }

    try {
      await ref.read(cardRepositoryProvider).updateCard(updated);
      if (!mounted) return;
      context.pop();
    } on AppFailure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.toString())),
      );
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(
      cardByIdProvider((deckId: widget.deckId, cardId: widget.cardId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa card'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: cardAsync.when(
              data: (card) => TextButton(
                onPressed:
                    (_currentValid(card) && !_submitting)
                        ? () => _save(card)
                        : null,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: cardAsync.when(
        data: (card) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildForm(card),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Không tìm thấy card',
          description: e.toString(),
        ),
      ),
    );
  }

  Widget _buildForm(FlashCard card) {
    return switch (card) {
      QaCard(:final front, :final back) => QaCardForm(
        key: ValueKey(card.id),
        initialFront: front,
        initialBack: back,
        onChange: ({required front, required back, required valid}) {
          setState(() {
            _qaFront = front;
            _qaBack = back;
            _qaValid = valid;
          });
        },
      ),
      ClozeCard(:final text) => ClozeCardForm(
        key: ValueKey(card.id),
        initialText: text,
        onChange: ({required text, required valid}) {
          setState(() {
            _clozeText = text;
            _clozeValid = valid;
          });
        },
      ),
      McqCard(:final question, :final options, :final correctIndex) =>
        McqCardForm(
          key: ValueKey(card.id),
          initialQuestion: question,
          initialOptions: options.toList(),
          initialCorrectIndex: correctIndex,
          onChange: ({
            required question,
            required options,
            required correctIndex,
            required valid,
          }) {
            setState(() {
              _mcqQuestion = question;
              _mcqOptions = options;
              _mcqCorrectIndex = correctIndex;
              _mcqValid = valid;
            });
          },
        ),
    };
  }
}
