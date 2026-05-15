import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/app.dart';
import 'package:zeno/features/auth/domain/auth_repository.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/domain/deck_repository.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';
import 'package:zeno/features/review/presentation/providers/review_providers.dart';
import 'package:zeno/features/user/domain/user_stats.dart';
import 'package:zeno/features/user/presentation/providers/user_stats_providers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDeckRepository extends Mock implements DeckRepository {}

/// A [ZenoApp] wrapper that stubs the auth, deck, and stats layers so the
/// router sees a signed-in user with an empty deck list (no Firebase needed).
Widget _authedApp() {
  final authRepo = _MockAuthRepository();
  const user = AuthUser(uid: 'test', email: 'test@zeno.app');
  when(authRepo.authStateChanges).thenAnswer((_) => Stream.value(user));
  when(() => authRepo.currentUser).thenReturn(user);

  final deckRepo = _MockDeckRepository();
  when(deckRepo.watchDecks).thenAnswer((_) => Stream.value(<Deck>[]));

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      deckRepositoryProvider.overrideWithValue(deckRepo),
      dueCardsAllProvider.overrideWith((ref) async => <FlashCard>[]),
      userStatsProvider.overrideWith(
        (ref) => Stream.value(const UserStats()),
      ),
    ],
    child: const ZenoApp(),
  );
}

void main() {
  testWidgets('App boots into Home tab by default', (tester) async {
    await tester.pumpWidget(_authedApp());
    await tester.pumpAndSettle();

    // AppBar title and nav bar both show 'Home'
    expect(find.text('Home'), findsWidgets);
    // The streak card is visible (streak starts at 0)
    expect(find.text('0'), findsWidgets);
  });

  testWidgets(
    'Tapping Library tab navigates to library screen',
    (tester) async {
      await tester.pumpWidget(_authedApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.library_books_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No decks yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Review tab navigates to review screen',
    (tester) async {
      await tester.pumpWidget(_authedApp());
      await tester.pumpAndSettle();

      // Use the NavigationBar destination icon specifically
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.psychology_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có card đến hạn'), findsOneWidget);
    },
  );
}
