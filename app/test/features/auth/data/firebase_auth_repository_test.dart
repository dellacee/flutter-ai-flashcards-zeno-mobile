import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
  late FakeFirebaseFirestore firestore;
  late FirebaseAuthRepository repo;

  setUp(() {
    auth = _MockFirebaseAuth();
    googleSignIn = _MockGoogleSignIn();
    firestore = FakeFirebaseFirestore();
    repo = FirebaseAuthRepository(
      firebaseAuth: auth,
      googleSignIn: googleSignIn,
      firestore: firestore,
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

  group('bootstrap user doc', () {
    _MockUser makeUser() {
      final user = _MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => user.email).thenReturn('a@b.com');
      when(() => user.displayName).thenReturn('Alice');
      when(() => user.photoURL).thenReturn(null);
      when(() => user.isAnonymous).thenReturn(false);
      return user;
    }

    test('creates default user doc on first sign-in', () async {
      final user = makeUser();
      final cred = _MockUserCredential();
      when(() => cred.user).thenReturn(user);
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => cred);

      await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      final snap = await firestore.collection('users').doc('u1').get();
      expect(snap.exists, isTrue);

      final data = snap.data()!;
      expect(data['email'], 'a@b.com');
      expect(data['displayName'], 'Alice');
      expect(data['photoURL'], isNull);
      expect(data['createdAt'], isNotNull);
      expect(data['lastSignInAt'], isNotNull);

      final settings = data['settings'] as Map<String, dynamic>;
      expect(settings['reviewTime'], '07:00');
      expect(settings['dailyNewCardLimit'], 20);
      expect(settings['theme'], 'system');
      expect(settings['locale'], 'vi');

      final stats = data['stats'] as Map<String, dynamic>;
      expect(stats['streak'], 0);
      expect(stats['totalReviews'], 0);
    });

    test('does not overwrite settings on subsequent sign-in', () async {
      // Pre-seed the doc with custom settings
      await firestore.collection('users').doc('u1').set({
        'displayName': 'Alice',
        'email': 'a@b.com',
        'photoURL': null,
        'createdAt': DateTime.now(),
        'lastSignInAt': DateTime.now(),
        'settings': {
          'reviewTime': '08:00',
          'dailyNewCardLimit': 30,
          'theme': 'dark',
          'locale': 'en',
        },
        'stats': {
          'streak': 5,
          'totalReviews': 100,
        },
      });

      final user = makeUser();
      final cred = _MockUserCredential();
      when(() => cred.user).thenReturn(user);
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => cred);

      await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      final snap = await firestore.collection('users').doc('u1').get();
      final data = snap.data()!;

      // lastSignInAt should be refreshed
      expect(data['lastSignInAt'], isNotNull);

      // Settings must be untouched
      final settings = data['settings'] as Map<String, dynamic>;
      expect(settings['locale'], 'en');
      expect(settings['theme'], 'dark');
      expect(settings['dailyNewCardLimit'], 30);

      // Stats must be untouched
      final stats = data['stats'] as Map<String, dynamic>;
      expect(stats['streak'], 5);
      expect(stats['totalReviews'], 100);
    });
  });
}
