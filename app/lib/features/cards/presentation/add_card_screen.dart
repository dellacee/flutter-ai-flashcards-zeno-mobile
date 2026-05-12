import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/cards/presentation/widgets/cloze_card_form.dart';
import 'package:zeno/features/cards/presentation/widgets/mcq_card_form.dart';
import 'package:zeno/features/cards/presentation/widgets/qa_card_form.dart';

/// The three flash-card variants the user can create.
enum CardType { qa, cloze, mcq }

/// Screen for adding a new flash card to [deckId].
///
/// A [SegmentedButton] lets the user pick the card type. The corresponding
/// form is shown below it. Form state is tracked per-type in fields so
/// toggling back to a previous type restores what was typed.
///
/// Design note: We keep per-type validity flags in plain fields rather than
/// using an IndexedStack. This avoids keeping all three form widgets alive
/// simultaneously; only the selected form is in the tree. The slight trade-off
/// is that typed text is lost if the user switches type, but that is acceptable
/// for V1.0 because switching type is a deliberate action.
class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  CardType _type = CardType.qa;

  // QA state
  String _qaFront = '';
  String _qaBack = '';
  bool _qaValid = false;

  // Cloze state
  String _clozeText = '';
  bool _clozeValid = false;

  // MCQ state
  String _mcqQuestion = '';
  List<String> _mcqOptions = const ['', ''];
  int _mcqCorrectIndex = 0;
  bool _mcqValid = false;

  bool _submitting = false;

  bool get _currentValid => switch (_type) {
    CardType.qa => _qaValid,
    CardType.cloze => _clozeValid,
    CardType.mcq => _mcqValid,
  };

  Future<void> _save() async {
    if (!_currentValid || _submitting) return;
    setState(() => _submitting = true);

    final draft = switch (_type) {
      CardType.qa => QaDraft(front: _qaFront.trim(), back: _qaBack.trim()),
      CardType.cloze => ClozeDraft(text: _clozeText.trim()),
      CardType.mcq => McqDraft(
        question: _mcqQuestion.trim(),
        options: _mcqOptions,
        correctIndex: _mcqCorrectIndex,
      ),
    };

    try {
      await ref
          .read(cardRepositoryProvider)
          .createCard(deckId: widget.deckId, draft: draft);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm card'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_currentValid && !_submitting) ? _save : null,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            SegmentedButton<CardType>(
              segments: const [
                ButtonSegment(
                  value: CardType.qa,
                  label: Text('Q/A'),
                  icon: Icon(Icons.help_outline),
                ),
                ButtonSegment(
                  value: CardType.cloze,
                  label: Text('Cloze'),
                  icon: Icon(Icons.short_text),
                ),
                ButtonSegment(
                  value: CardType.mcq,
                  label: Text('MCQ'),
                  icon: Icon(Icons.checklist),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),

            const SizedBox(height: 16),

            // Active form
            switch (_type) {
              CardType.qa => QaCardForm(
                key: const ValueKey(CardType.qa),
                onChange: ({required front, required back, required valid}) {
                  setState(() {
                    _qaFront = front;
                    _qaBack = back;
                    _qaValid = valid;
                  });
                },
              ),
              CardType.cloze => ClozeCardForm(
                key: const ValueKey(CardType.cloze),
                onChange: ({required text, required valid}) {
                  setState(() {
                    _clozeText = text;
                    _clozeValid = valid;
                  });
                },
              ),
              CardType.mcq => McqCardForm(
                key: const ValueKey(CardType.mcq),
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
            },
          ],
        ),
      ),
    );
  }
}
