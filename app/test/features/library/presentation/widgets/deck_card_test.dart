import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/presentation/widgets/deck_card.dart';

Deck _makeDeck({int dueCount = 0, int cardCount = 12}) => Deck(
      id: 'd1',
      title: 'Sinh học 12',
      description: 'Chương 1-3',
      cardCount: cardCount,
      dueCount: dueCount,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  testWidgets('renders title and card count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DeckCard(deck: _makeDeck()))),
    );
    expect(find.text('Sinh học 12'), findsOneWidget);
    expect(find.textContaining('12 cards'), findsOneWidget);
  });

  testWidgets('shows due pill when dueCount > 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DeckCard(deck: _makeDeck(dueCount: 3))),
      ),
    );
    expect(find.textContaining('3 due'), findsOneWidget);
  });

  testWidgets('hides due pill when dueCount is 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DeckCard(deck: _makeDeck())),
      ),
    );
    expect(find.textContaining('due'), findsNothing);
  });
}
