import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/app.dart';
import 'package:zeno/features/auth/domain/auth_repository.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// A [ZenoApp] wrapper that stubs the auth layer so the router sees a
/// signed-in user and routes directly to the main shell instead of /sign-in.
Widget _authedApp() {
  final repo = _MockAuthRepository();
  const user = AuthUser(uid: 'test', email: 'test@zeno.app');
  when(repo.authStateChanges).thenAnswer((_) => Stream.value(user));
  when(() => repo.currentUser).thenReturn(user);

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: const ZenoApp(),
  );
}

void main() {
  testWidgets('App boots into Home tab by default', (tester) async {
    await tester.pumpWidget(_authedApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets); // app bar title
    expect(find.text('Welcome to Zeno'), findsOneWidget);
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

      await tester.tap(find.byIcon(Icons.psychology_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to review'), findsOneWidget);
    },
  );
}
