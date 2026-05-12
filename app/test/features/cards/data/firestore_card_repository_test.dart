import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/cards/data/firestore_card_repository.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockUser extends Mock implements fb.User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth auth;
  late FirestoreCardRepository repo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    // Pre-seed parent deck (cardCount starts at 0)
    await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .set({
      'title': 'Test',
      'cardCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    repo = FirestoreCardRepository(firestore: firestore, auth: auth);
  });

  // ---------------------------------------------------------------------------
  // 1. createCard QA — writes correct shape AND increments cardCount
  // ---------------------------------------------------------------------------
  test('createCard QA writes correct shape and increments deck cardCount',
      () async {
    final card = await repo.createCard(
      deckId: 'd1',
      draft: const QaDraft(
        front: 'What is Dart?',
        back: 'A language by Google',
      ),
    );

    // returned card has correct fields
    expect(card.id, isNotEmpty);
    expect(card, isA<QaCard>());
    final qa = card as QaCard;
    expect(qa.front, 'What is Dart?');
    expect(qa.back, 'A language by Google');
    expect(qa.deckId, 'd1');

    // Firestore doc shape
    final cardSnap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc(card.id)
        .get();
    expect(cardSnap.exists, isTrue);
    expect(cardSnap.data()!['type'], 'qa');
    expect(cardSnap.data()!['front'], 'What is Dart?');
    expect(cardSnap.data()!['back'], 'A language by Google');

    // Deck cardCount bumped from 0 → 1
    final deckSnap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .get();
    expect(deckSnap.data()!['cardCount'], 1);
  });

  // ---------------------------------------------------------------------------
  // 2. createCard cloze — writes type='cloze' and text field
  // ---------------------------------------------------------------------------
  test('createCard cloze writes type=cloze and text field', () async {
    final card = await repo.createCard(
      deckId: 'd1',
      draft: const ClozeDraft(
        text: 'Mitochondria is the {{c1::powerhouse}} of the cell',
      ),
    );

    expect(card, isA<ClozeCard>());
    final cloze = card as ClozeCard;
    expect(cloze.text, contains('powerhouse'));

    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc(card.id)
        .get();
    expect(snap.data()!['type'], 'cloze');
    expect(snap.data()!['text'], contains('powerhouse'));
  });

  // ---------------------------------------------------------------------------
  // 3. createCard mcq — writes options array and correctIndex
  // ---------------------------------------------------------------------------
  test('createCard mcq writes options array and correctIndex', () async {
    final card = await repo.createCard(
      deckId: 'd1',
      draft: const McqDraft(
        question: 'Which planet is closest to the Sun?',
        options: ['Venus', 'Mercury', 'Mars', 'Earth'],
        correctIndex: 1,
      ),
    );

    expect(card, isA<McqCard>());
    final mcq = card as McqCard;
    expect(mcq.options, ['Venus', 'Mercury', 'Mars', 'Earth']);
    expect(mcq.correctIndex, 1);

    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc(card.id)
        .get();
    expect(snap.data()!['type'], 'mcq');
    expect(snap.data()!['options'], ['Venus', 'Mercury', 'Mars', 'Earth']);
    expect(snap.data()!['correctIndex'], 1);
  });

  // ---------------------------------------------------------------------------
  // 4. createCard returns card with non-empty id and timestamps
  // ---------------------------------------------------------------------------
  test('createCard returns card with non-empty id and timestamps', () async {
    final card = await repo.createCard(
      deckId: 'd1',
      draft: const QaDraft(front: 'Q', back: 'A'),
    );

    expect(card.id, isNotEmpty);
    expect(card.createdAt, isNotNull);
    expect(card.updatedAt, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // 5. watchCards emits cards ordered by createdAt desc (B after A → B first)
  // ---------------------------------------------------------------------------
  test('watchCards emits cards ordered by createdAt descending', () async {
    final earlier = DateTime(2026, 5, 8, 10);
    final later = DateTime(2026, 5, 8, 10, 1);

    // Write card A with earlier timestamp directly so we control order
    final refA = firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc();
    await refA.set({
      'type': 'qa',
      'front': 'A',
      'back': 'A answer',
      'createdAt': Timestamp.fromDate(earlier),
      'updatedAt': Timestamp.fromDate(earlier),
    });

    final refB = firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc();
    await refB.set({
      'type': 'qa',
      'front': 'B',
      'back': 'B answer',
      'createdAt': Timestamp.fromDate(later),
      'updatedAt': Timestamp.fromDate(later),
    });

    final cards = await repo.watchCards('d1').first;
    expect(cards, hasLength(2));
    // B was created later, so it should be first (descending)
    expect((cards[0] as QaCard).front, 'B');
    expect((cards[1] as QaCard).front, 'A');
  });

  // ---------------------------------------------------------------------------
  // 6. getCard throws AppFailure.notFound for missing cardId
  // ---------------------------------------------------------------------------
  test('getCard throws AppFailure.notFound for missing cardId', () async {
    await expectLater(
      repo.getCard(deckId: 'd1', cardId: 'nonexistent'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.whenOrNull(notFound: (message) => message),
          'notFound message',
          contains('nonexistent'),
        ),
      ),
    );
  });

  // ---------------------------------------------------------------------------
  // 7. updateCard persists changes and bumps updatedAt
  // ---------------------------------------------------------------------------
  test('updateCard persists changes and bumps updatedAt', () async {
    final created = await repo.createCard(
      deckId: 'd1',
      draft: const QaDraft(front: 'Original Q', back: 'Original A'),
    );

    final originalUpdatedAt = created.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final modified = (created as QaCard).copyWith(
      front: 'Modified Q',
      back: 'Modified A',
    );
    await repo.updateCard(modified);

    // Read back from Firestore
    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc(created.id)
        .get();

    expect(snap.data()!['front'], 'Modified Q');
    expect(snap.data()!['back'], 'Modified A');

    final persistedUpdatedAt =
        (snap.data()!['updatedAt'] as Timestamp).toDate();
    expect(
      persistedUpdatedAt.isAfter(originalUpdatedAt),
      isTrue,
      reason: 'updatedAt must be bumped after update',
    );
  });

  // ---------------------------------------------------------------------------
  // 8. deleteCard removes doc AND decrements deck's cardCount
  // ---------------------------------------------------------------------------
  test('deleteCard removes doc and decrements deck cardCount', () async {
    // Create two cards so cardCount goes to 2
    final card1 = await repo.createCard(
      deckId: 'd1',
      draft: const QaDraft(front: 'Q1', back: 'A1'),
    );
    await repo.createCard(
      deckId: 'd1',
      draft: const QaDraft(front: 'Q2', back: 'A2'),
    );

    // Verify cardCount is 2
    final beforeSnap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .get();
    expect(beforeSnap.data()!['cardCount'], 2);

    // Delete card1
    await repo.deleteCard(deckId: 'd1', cardId: card1.id);

    // Card doc should be gone
    final cardSnap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .collection('cards')
        .doc(card1.id)
        .get();
    expect(cardSnap.exists, isFalse);

    // cardCount decremented from 2 → 1
    final deckSnap = await firestore
        .collection('users')
        .doc('u1')
        .collection('decks')
        .doc('d1')
        .get();
    expect(deckSnap.data()!['cardCount'], 1);
  });

  // ---------------------------------------------------------------------------
  // 9. Operations without a current user throw AppFailure.auth
  // ---------------------------------------------------------------------------
  group('no current user', () {
    setUp(() {
      when(() => auth.currentUser).thenReturn(null);
    });

    test('watchCards throws AppFailure.auth(code: no-current-user)', () {
      expect(
        () => repo.watchCards('d1'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('getCard throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.getCard(deckId: 'd1', cardId: 'c1'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('createCard throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.createCard(
          deckId: 'd1',
          draft: const QaDraft(front: 'Q', back: 'A'),
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('updateCard throws AppFailure.auth(code: no-current-user)', () async {
      // Build a card object manually — no Firestore needed
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final fakeCard = FlashCard.qa(
        id: 'c1',
        deckId: 'd1',
        front: 'Q',
        back: 'A',
        createdAt: epoch,
        updatedAt: epoch,
      );
      await expectLater(
        repo.updateCard(fakeCard),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.whenOrNull(auth: (code, _) => code),
            'auth code',
            'no-current-user',
          ),
        ),
      );
    });

    test('deleteCard throws AppFailure.auth(code: no-current-user)', () async {
      await expectLater(
        repo.deleteCard(deckId: 'd1', cardId: 'c1'),
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
