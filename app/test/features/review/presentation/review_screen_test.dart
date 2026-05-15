import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/review/domain/review_rating.dart';
import 'package:zeno/features/review/presentation/providers/review_providers.dart';
import 'package:zeno/features/review/presentation/review_screen.dart';

class _MockCardRepository extends Mock implements CardRepository {}

void main() {
  late _MockCardRepository mockRepo;

  setUp(() {
    mockRepo = _MockCardRepository();
    registerFallbackValue(ReviewRating.good);
  });

  final card1 = FlashCard.qa(
    id: 'c1',
    deckId: 'd1',
    front: 'Q1',
    back: 'A1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final card2 = FlashCard.qa(
    id: 'c2',
    deckId: 'd1',
    front: 'Q2',
    back: 'A2',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Widget buildScreen(List<FlashCard> cards) {
    return ProviderScope(
      overrides: [
        cardRepositoryProvider.overrideWithValue(mockRepo),
        dueCardsAllProvider.overrideWith((ref) async => cards),
      ],
      child: const MaterialApp(home: ReviewScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Empty state — no cards due
  // ---------------------------------------------------------------------------
  testWidgets('renders empty state when no cards due', (tester) async {
    await tester.pumpWidget(buildScreen([]));
    await tester.pumpAndSettle();

    expect(find.text('Không có card đến hạn'), findsOneWidget);
    // Rating buttons must NOT appear when empty
    expect(find.text('Tốt'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // 2. First card front shown; tap flips to back
  // ---------------------------------------------------------------------------
  testWidgets('renders first card front and flips to back on tap',
      (tester) async {
    await tester.pumpWidget(buildScreen([card1, card2]));
    await tester.pumpAndSettle();

    // Front visible
    expect(find.text('Q1'), findsOneWidget);
    // Back not yet visible
    expect(find.text('A1'), findsNothing);

    // Tap the card to flip
    await tester.tap(find.text('Q1'));
    await tester.pumpAndSettle();

    // Back now visible
    expect(find.text('A1'), findsOneWidget);

    // Rating buttons should now appear
    expect(find.text('Tốt'), findsOneWidget);
    expect(find.text('Lại'), findsOneWidget);
    expect(find.text('Khó'), findsOneWidget);
    expect(find.text('Dễ'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 3. Rating Good calls submitReview then advances to next card
  // ---------------------------------------------------------------------------
  testWidgets('calls submitReview with Good rating and advances card',
      (tester) async {
    when(
      () => mockRepo.submitReview(
        deckId: any(named: 'deckId'),
        cardId: any(named: 'cardId'),
        rating: any(named: 'rating'),
        reviewedAt: any(named: 'reviewedAt'),
      ),
    ).thenAnswer((_) async => card1);

    await tester.pumpWidget(buildScreen([card1, card2]));
    await tester.pumpAndSettle();

    // Flip to see the back
    await tester.tap(find.text('Q1'));
    await tester.pumpAndSettle();

    // Tap Good
    await tester.tap(find.text('Tốt'));
    await tester.pumpAndSettle();

    // submitReview should have been called once
    verify(
      () => mockRepo.submitReview(
        deckId: 'd1',
        cardId: 'c1',
        rating: ReviewRating.good,
        reviewedAt: any(named: 'reviewedAt'),
      ),
    ).called(1);

    // Advanced to card2
    expect(find.text('Q2'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 4. Done state after last card is rated
  // ---------------------------------------------------------------------------
  testWidgets('shows done state after last card is rated', (tester) async {
    when(
      () => mockRepo.submitReview(
        deckId: any(named: 'deckId'),
        cardId: any(named: 'cardId'),
        rating: any(named: 'rating'),
        reviewedAt: any(named: 'reviewedAt'),
      ),
    ).thenAnswer((_) async => card1);

    await tester.pumpWidget(buildScreen([card1]));
    await tester.pumpAndSettle();

    // Flip and rate
    await tester.tap(find.text('Q1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tốt'));
    await tester.pumpAndSettle();

    // Done state — title includes the emoji
    expect(find.text('🎉 Hôm nay xong!'), findsOneWidget);
  });
}
