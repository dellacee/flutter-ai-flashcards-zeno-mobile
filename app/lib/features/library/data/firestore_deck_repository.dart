import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/logger/app_logger.dart';
import 'package:zeno/features/library/data/deck_dto.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/domain/deck_repository.dart';

class FirestoreDeckRepository implements DeckRepository {
  FirestoreDeckRepository({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final _log = appLog('library.deck_repository');

  CollectionReference<Map<String, dynamic>> get _decksCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppFailure.auth(
        code: 'no-current-user',
        message: 'Bạn cần đăng nhập để thao tác với deck.',
      );
    }
    return _firestore.collection('users').doc(uid).collection('decks');
  }

  @override
  Stream<List<Deck>> watchDecks() {
    try {
      final collection = _decksCollection;
      return collection
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(DeckDto.fromFirestore)
                .toList(),
          );
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      _log.warning('watchDecks error', e, st);
      throw AppFailure.unknown(message: 'Failed to watch decks', cause: e);
    }
  }

  @override
  Future<Deck> getDeck(String id) async {
    try {
      final snap = await _decksCollection.doc(id).get();
      if (!snap.exists) {
        throw AppFailure.notFound(message: 'Deck $id not found');
      }
      return DeckDto.fromFirestore(snap);
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('getDeck FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('getDeck error', e, st);
      throw AppFailure.unknown(message: 'Failed to get deck $id', cause: e);
    }
  }

  @override
  Future<Deck> createDeck({
    required String title,
    String? description,
    List<String> tags = const [],
    String coverColor = 'indigo',
  }) async {
    try {
      final now = DateTime.now();
      final deck = Deck(
        id: '',
        title: title,
        description: description,
        tags: tags,
        coverColor: coverColor,
        createdAt: now,
        updatedAt: now,
      );
      final docRef = _decksCollection.doc();
      await docRef.set(DeckDto.toFirestore(deck));
      return deck.copyWith(id: docRef.id);
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('createDeck FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('createDeck error', e, st);
      throw AppFailure.unknown(message: 'Failed to create deck', cause: e);
    }
  }

  @override
  Future<void> updateDeck(Deck deck) async {
    try {
      final now = DateTime.now();
      final updated = deck.copyWith(updatedAt: now);
      await _decksCollection.doc(deck.id).update(DeckDto.toFirestore(updated));
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('updateDeck FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('updateDeck error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to update deck ${deck.id}',
        cause: e,
      );
    }
  }

  @override
  Future<void> deleteDeck(String id) async {
    try {
      await _decksCollection.doc(id).delete();
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('deleteDeck FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('deleteDeck error', e, st);
      throw AppFailure.unknown(message: 'Failed to delete deck $id', cause: e);
    }
  }

  @override
  Future<int> recountDue({
    required String deckId,
    required DateTime asOf,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw const AppFailure.auth(
          code: 'no-current-user',
          message: 'Bạn cần đăng nhập.',
        );
      }
      final asOfTs = Timestamp.fromDate(asOf);
      final cardsRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('decks')
          .doc(deckId)
          .collection('cards');

      final newCards = await cardsRef
          .where('progress.state', isEqualTo: 'newCard')
          .get();
      final dueReview = await cardsRef
          .where('progress.due', isLessThanOrEqualTo: asOfTs)
          .get();

      // Union by docId to avoid double-counting
      final ids = <String>{
        ...newCards.docs.map((d) => d.id),
        ...dueReview.docs.map((d) => d.id),
      };
      final count = ids.length;

      await _decksCollection.doc(deckId).update({'dueCount': count});
      return count;
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('recountDue FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('recountDue error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to recount due cards for deck $deckId',
        cause: e,
      );
    }
  }
}
