import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/auth/domain/auth_repository.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';
import 'package:zeno/features/auth/presentation/sign_in_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.authStateChanges()).thenAnswer((_) => const Stream.empty());
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: child),
      );

  testWidgets('renders logo, tagline, email form, Google button',
      (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    expect(find.text('Zeno'), findsOneWidget);
    expect(find.textContaining('Học từ bất kỳ thứ gì'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets); // submit + maybe toggle
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });

  testWidgets('toggle switches to register mode', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký'), findsWidgets);
    expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
  });

  testWidgets('Google button calls repo.signInWithGoogle', (tester) async {
    when(() => repo.signInWithGoogle()).thenAnswer(
      (_) async => const AuthUser(uid: 'u1', email: 'a@b.com'),
    );

    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pump(); // start the future

    verify(() => repo.signInWithGoogle()).called(1);
  });

  testWidgets('email submit calls repo.signInWithEmail in sign-in mode',
      (tester) async {
    when(() => repo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer(
      (_) async => const AuthUser(uid: 'u1', email: 'a@b.com'),
    );

    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'hunter22');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    verify(() => repo.signInWithEmail(email: 'a@b.com', password: 'hunter22'))
        .called(1);
  });
}
