import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/widgets/card_tile.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: ListView(children: [child])),
      );

  testWidgets('QaCard shows front and back', (tester) async {
    final qa = FlashCard.qa(
      id: 'c1',
      deckId: 'd1',
      front: 'Q front',
      back: 'A back',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      wrap(
        CardTile(card: qa, onTap: () {}, onDelete: () {}),
      ),
    );
    expect(find.text('Q front'), findsOneWidget);
    expect(find.text('A back'), findsOneWidget);
  });

  testWidgets('ClozeCard shows text with marker replaced by [word]',
      (tester) async {
    final cloze = FlashCard.cloze(
      id: 'c2',
      deckId: 'd1',
      text: 'Mitochondria is the {{c1::powerhouse}} of the cell',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      wrap(
        CardTile(card: cloze, onTap: () {}, onDelete: () {}),
      ),
    );
    expect(
      find.text('Mitochondria is the [powerhouse] of the cell'),
      findsOneWidget,
    );
  });

  testWidgets('McqCard shows question and option count', (tester) async {
    final mcq = FlashCard.mcq(
      id: 'c3',
      deckId: 'd1',
      question: 'What is 2+2?',
      options: const ['3', '4', '5'],
      correctIndex: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      wrap(
        CardTile(card: mcq, onTap: () {}, onDelete: () {}),
      ),
    );
    expect(find.text('What is 2+2?'), findsOneWidget);
    expect(find.text('3 lựa chọn'), findsOneWidget);
  });
}
