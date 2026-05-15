import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/logger/app_logger.dart';
import 'package:zeno/features/cards/data/card_dto.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/review/domain/card_state.dart';
import 'package:zeno/features/review/domain/fsrs_scheduler.dart';
import 'package:zeno/features/review/domain/review_progress.dart';
import 'package:zeno/features/review/domain/review_rating.dart';
import 'package:zeno/features/user/data/user_stats_repository.dart';

class FirestoreCardRepository implements CardRepository {
  FirestoreCardRepository({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
    required UserStatsRepository statsRepository,
  })  : _firestore = firestore,
        _auth = auth,
        _statsRepository = statsRepository;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final UserStatsRepository _statsRepository;
  final _log = appLog('cards.card_repository');

  CollectionReference<Map<String, dynamic>> _cardsCollection(String deckId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppFailure.auth(
        code: 'no-current-user',
        message: 'Bạn cần đăng nhập.',
      );
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .collection('cards');
  }

  DocumentReference<Map<String, dynamic>> _deckDoc(String deckId) {
    final uid = _auth.currentUser!.uid; // _cardsCollection already validated
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId);
  }

  @override
  Stream<List<FlashCard>> watchCards(String deckId) {
    try {
      return _cardsCollection(deckId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => CardDto.fromFirestore(doc, deckId: deckId))
                .toList(),
          );
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      _log.warning('watchCards error', e, st);
      throw AppFailure.unknown(message: 'Failed to watch cards', cause: e);
    }
  }

  @override
  Future<FlashCard> getCard({
    required String deckId,
    required String cardId,
  }) async {
    try {
      final snap = await _cardsCollection(deckId).doc(cardId).get();
      if (!snap.exists) {
        throw AppFailure.notFound(message: 'Card $cardId not found');
      }
      return CardDto.fromFirestore(snap, deckId: deckId);
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('getCard FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('getCard error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to get card $cardId',
        cause: e,
      );
    }
  }

  @override
  Future<FlashCard> createCard({
    required String deckId,
    required NewCardDraft draft,
  }) async {
    try {
      final now = DateTime.now();
      final cardRef = _cardsCollection(deckId).doc();
      final deckRef = _deckDoc(deckId);

      final card = switch (draft) {
        QaDraft() => FlashCard.qa(
            id: cardRef.id,
            deckId: deckId,
            front: draft.front,
            back: draft.back,
            createdAt: now,
            updatedAt: now,
          ),
        ClozeDraft() => FlashCard.cloze(
            id: cardRef.id,
            deckId: deckId,
            text: draft.text,
            createdAt: now,
            updatedAt: now,
          ),
        McqDraft() => FlashCard.mcq(
            id: cardRef.id,
            deckId: deckId,
            question: draft.question,
            options: draft.options,
            correctIndex: draft.correctIndex,
            createdAt: now,
            updatedAt: now,
          ),
      };

      final batch = _firestore.batch()
        ..set(cardRef, CardDto.toFirestore(card))
        ..update(deckRef, {
          'cardCount': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      await batch.commit();

      return card;
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('createCard FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('createCard error', e, st);
      throw AppFailure.unknown(message: 'Failed to create card', cause: e);
    }
  }

  @override
  Future<void> updateCard(FlashCard card) async {
    try {
      final now = DateTime.now();
      final updated = switch (card) {
        final QaCard c => c.copyWith(updatedAt: now),
        final ClozeCard c => c.copyWith(updatedAt: now),
        final McqCard c => c.copyWith(updatedAt: now),
      };

      await _cardsCollection(card.deckId)
          .doc(card.id)
          .update(CardDto.toFirestore(updated));

      // Also update parent deck's updatedAt so the library list re-sorts.
      await _deckDoc(card.deckId).update({'updatedAt': Timestamp.now()});
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('updateCard FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('updateCard error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to update card ${card.id}',
        cause: e,
      );
    }
  }

  @override
  Future<void> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    try {
      final cardRef = _cardsCollection(deckId).doc(cardId);
      final deckRef = _deckDoc(deckId);

      final batch = _firestore.batch()
        ..delete(cardRef)
        ..update(deckRef, {
          'cardCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });
      await batch.commit();
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('deleteCard FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('deleteCard error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to delete card $cardId',
        cause: e,
      );
    }
  }

  /// Returns true if [p] is due at [t]: new cards are always due,
  /// and reviewed cards are due when their due date is on or before [t].
  bool _isDueAt(ReviewProgress p, DateTime t) {
    if (p.state == CardState.newCard) return true;
    if (p.due == null) return true;
    return p.due!.isBefore(t) || p.due!.isAtSameMomentAs(t);
  }

  @override
  Future<FlashCard> submitReview({
    required String deckId,
    required String cardId,
    required ReviewRating rating,
    required DateTime reviewedAt,
  }) async {
    try {
      final card = await getCard(deckId: deckId, cardId: cardId);
      final currentProgress = card.progress;

      final next = const FsrsScheduler().schedule(
        current: currentProgress,
        rating: rating,
        reviewedAt: reviewedAt,
      );

      final updated = card.copyWithProgress(next);

      final cardRef = _cardsCollection(deckId).doc(cardId);
      final deckRef = _deckDoc(deckId);

      final wasDue = _isDueAt(currentProgress, reviewedAt);
      final isNowDue = _isDueAt(next, reviewedAt);
      final shouldDecrementDue = wasDue && !isNowDue;

      final batch = _firestore.batch()
        ..set(cardRef, CardDto.toFirestore(updated), SetOptions(merge: true));

      if (shouldDecrementDue) {
        batch.update(deckRef, {
          'dueCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });
      } else {
        batch.update(deckRef, {'updatedAt': Timestamp.now()});
      }

      await batch.commit();

      try {
        await _statsRepository.applyReview(reviewedAt: reviewedAt);
      } catch (e, st) {
        _log.warning('stats update failed (non-fatal)', e, st);
      }

      return updated;
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (e, st) {
      _log.warning('submitReview FirebaseException: ${e.code}', e, st);
      throw AppFailure.unknown(message: e.message, cause: e);
    } catch (e, st) {
      _log.warning('submitReview error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to submit review for card $cardId',
        cause: e,
      );
    }
  }
}
