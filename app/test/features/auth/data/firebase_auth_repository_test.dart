import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/auth/data/firebase_auth_repository.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockUserCredential extends Mock implements fb.UserCredential {}

class _MockUser extends Mock implements fb.User {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late _MockFirebaseAuth auth;
  late _MockGoogleSignIn googleSignIn;
  late FirebaseAuthRepository repo;

  setUp(() {
    auth = _MockFirebaseAuth();
    googleSignIn = _MockGoogleSignIn();
    repo = FirebaseAuthRepository(
      firebaseAuth: auth,
      googleSignIn: googleSignIn,
    );
  });

  group('signInWithEmail', () {
    test('returns mapped AuthUser on success', () async {
      final user = _MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => user.email).thenReturn('a@b.com');
      when(() => user.displayName).thenReturn('Alice');
      when(() => user.photoURL).thenReturn(null);
      when(() => user.isAnonymous).thenReturn(false);

      final cred = _MockUserCredential();
      when(() => cred.user).thenReturn(user);

      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => cred);

      final result = await repo.signInWithEmail(
        email: 'a@b.com',
        password: 'pw',
      );

      expect(result.uid, 'u1');
      expect(result.email, 'a@b.com');
      expect(result.displayName, 'Alice');
    });

    test(
      'translates wrong-password FirebaseAuthException to AppFailure.auth',
      () async {
        when(
          () => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          fb.FirebaseAuthException(
            code: 'wrong-password',
            message: 'bad pw',
          ),
        );

        await expectLater(
          repo.signInWithEmail(email: 'a@b.com', password: 'pw'),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.whenOrNull(auth: (code, _) => code),
              'auth code',
              'wrong-password',
            ),
          ),
        );
      },
    );
  });

  group('signInWithGoogle', () {
    test('throws AppFailure.auth(cancelled) when user cancels', () async {
      when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

      await expectLater(
        repo.signInWithGoogle(),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'cancelled',
          ),
        ),
      );
    });
  });
}
