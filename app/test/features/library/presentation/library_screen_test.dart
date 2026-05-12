import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/domain/deck_repository.dart';
import 'package:zeno/features/library/presentation/library_screen.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';

class _MockDeckRepository extends Mock implements DeckRepository {}

void main() {
  late _MockDeckRepository repo;

  setUp(() {
    repo = _MockDeckRepository();
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          deckRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('shows empty state when no decks', (tester) async {
    when(repo.watchDecks).thenAnswer((_) => Stream.value(<Deck>[]));
    await tester.pumpWidget(wrap(const LibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('No decks yet'), findsOneWidget);
  });

  testWidgets('renders deck list when decks exist', (tester) async {
    final decks = [
      Deck(
        id: 'd1',
        title: 'Sinh học',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      Deck(
        id: 'd2',
        title: 'Toán',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];
    when(repo.watchDecks).thenAnswer((_) => Stream.value(decks));
    await tester.pumpWidget(wrap(const LibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sinh học'), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);
  });
}
