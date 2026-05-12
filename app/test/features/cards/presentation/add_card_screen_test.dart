import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/add_card_screen.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';

class _MockCardRepository extends Mock implements CardRepository {}

void main() {
  // QaDraft is a concrete subclass of sealed NewCardDraft — use it as fallback.
  setUpAll(() {
    registerFallbackValue(const QaDraft(front: '', back: ''));
  });

  late _MockCardRepository mockRepo;

  setUp(() {
    mockRepo = _MockCardRepository();
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          cardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('Save button disabled when QA form is empty', (tester) async {
    await tester.pumpWidget(wrap(const AddCardScreen(deckId: 'd1')));
    await tester.pump();

    // Find the Save TextButton in the AppBar actions.
    final saveButton = find.widgetWithText(TextButton, 'Lưu');
    expect(saveButton, findsOneWidget);

    final btn = tester.widget<TextButton>(saveButton);
    expect(btn.onPressed, isNull);
  });

  testWidgets(
    'Save button enabled after filling QA fields and calls createCard',
    (tester) async {
      final now = DateTime(2026);
      when(
        () => mockRepo.createCard(
          deckId: any(named: 'deckId'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer(
        (_) async => FlashCard.qa(
          id: 'new',
          deckId: 'd1',
          front: 'Hello',
          back: 'World',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(wrap(const AddCardScreen(deckId: 'd1')));
      await tester.pump();

      // Fill front field.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Hello');
      await tester.pump();

      // Fill back field.
      await tester.enterText(fields.at(1), 'World');
      await tester.pump();

      // Save button should now be enabled.
      final saveButton = find.widgetWithText(TextButton, 'Lưu');
      final btn = tester.widget<TextButton>(saveButton);
      expect(btn.onPressed, isNotNull);

      // Tap Save.
      await tester.tap(saveButton);
      await tester.pump();

      // Verify createCard was called with the right draft.
      final captured = verify(
        () => mockRepo.createCard(
          deckId: 'd1',
          draft: captureAny(named: 'draft'),
        ),
      ).captured;

      expect(captured.length, 1);
      final draft = captured.first as QaDraft;
      expect(draft.front, 'Hello');
      expect(draft.back, 'World');
    },
  );
}
