import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/library/data/firestore_deck_repository.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockUser extends Mock implements fb.User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth auth;
  late FirestoreDeckRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);
    repo = FirestoreDeckRepository(firestore: firestore, auth: auth);
  });

  group('createDeck', () {
    test(
      'writes to user-scoped path and returns Deck with non-empty id and '
      'correct title',
      () async {
        final deck = await repo.createDeck(title: 'My Deck');

        expect(deck.id, isNotEmpty);
        expect(deck.title, 'My Deck');
        expect(deck.createdAt, isNotNull);
        expect(deck.updatedAt, isNotNull);

        // Verify it was written under the correct path
        final snap = await firestore
            .collection('users')
            .doc('u1')
            .collection('decks')
            .doc(deck.id)
            .get();
        expect(snap.exists, isTrue);
        expect(snap.data()!['title'], 'My Deck');
      },
    );

    test('sets default values for optional fields', () async {
      final deck = await repo.createDeck(title: 'Defaults Deck');

      expect(deck.coverColor, 'indigo');
      expect(deck.tags, isEmpty);
      expect(deck.cardCount, 0);
      expect(deck.dueCount, 0);
      expect(deck.description, isNull);
    });
  });

  group('watchDecks', () {
    test('emits decks ordered by updatedAt descending (newest first)',
        () async {
      final now = DateTime(2026, 5, 8, 10);

      // Create deck A with an older updatedAt
      final deckA = await repo.createDeck(title: 'Deck A');
      await firestore
          .collection('users')
          .doc('u1')
          .collection('decks')
          .doc(deckA.id)
          .update({
        'updatedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });

      // Create deck B with a newer updatedAt
      final deckB = await repo.createDeck(title: 'Deck B');
      await firestore
          .collection('users')
          .doc('u1')
          .collection('decks')
          .doc(deckB.id)
          .update({
        'updatedAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
        'createdAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      });

      final decks = await repo.watchDecks().first;

      expect(decks, hasLength(2));
      expect(decks[0].id, deckB.id, reason: 'Deck B is newer, should be first');
      expect(decks[1].id, deckA.id);
    });
  });

  group('getDeck', () {
    test('returns the deck for an existing id', () async {
      final created = await repo.createDeck(
        title: 'Test Deck',
        description: 'A description',
        tags: ['math', 'science'],
      );

      final fetched = await repo.getDeck(created.id);

      expect(fetched.id, created.id);
      expect(fetched.title, 'Test Deck');
      expect(fetched.description, 'A description');
      expect(fetched.tags, ['math', 'science']);
    });

    test('throws AppFailure.notFound for a missing id', () async {
      await expectLater(
        repo.getDeck('non-existent-id'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(notFound: (message) => message),
            'notFound message',
            contains('non-existent-id'),
          ),
        ),
      );
    });
  });

  group('updateDeck', () {
    test('overwrites mutable fields and bumps updatedAt', () async {
      final created = await repo.createDeck(title: 'Original');

      // Wait slightly to ensure updatedAt changes
      final beforeUpdate = created.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final modified = created.copyWith(
        title: 'Updated Title',
        description: 'New description',
        coverColor: 'rose',
      );
      await repo.updateDeck(modified);

      // Read back from Firestore
      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('decks')
          .doc(created.id)
          .get();

      expect(snap.data()!['title'], 'Updated Title');
      expect(snap.data()!['description'], 'New description');
      expect(snap.data()!['coverColor'], 'rose');

      final persistedUpdatedAt =
          (snap.data()!['updatedAt'] as Timestamp).toDate();
      expect(
        persistedUpdatedAt.isAfter(beforeUpdate),
        isTrue,
        reason: 'updatedAt must be bumped to a time after the deck was created',
      );
    });
  });

  group('deleteDeck', () {
    test('removes the doc from Firestore', () async {
      final deck = await repo.createDeck(title: 'To Delete');

      await repo.deleteDeck(deck.id);

      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('decks')
          .doc(deck.id)
          .get();
      expect(snap.exists, isFalse);
    });
  });

  group('no current user', () {
    setUp(() {
      when(() => auth.currentUser).thenReturn(null);
    });

    test('createDeck throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.createDeck(title: 'Should fail'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('getDeck throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.getDeck('any-id'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('updateDeck throws AppFailure.auth(code: no-current-user)', () async {
      // We need a valid Deck to attempt the update
      when(() => auth.currentUser).thenReturn(null);
      final fakeDeck = await () async {
        // Reset to logged-in user briefly to create a deck
        final user = _MockUser();
        when(() => user.uid).thenReturn('u1');
        when(() => auth.currentUser).thenReturn(user);
        final d = await repo.createDeck(title: 'Temp');
        when(() => auth.currentUser).thenReturn(null);
        return d;
      }();

      await expectLater(
        repo.updateDeck(fakeDeck),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('deleteDeck throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.deleteDeck('any-id'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('watchDecks throws AppFailure.auth(code: no-current-user)', () async {
      expect(
        () => repo.watchDecks(),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });
  });
}
