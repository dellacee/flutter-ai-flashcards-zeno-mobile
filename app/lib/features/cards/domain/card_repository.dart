import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/review/domain/review_rating.dart';

sealed class NewCardDraft {
  const NewCardDraft();
}

class QaDraft extends NewCardDraft {
  const QaDraft({required this.front, required this.back});
  final String front;
  final String back;
}

class ClozeDraft extends NewCardDraft {
  const ClozeDraft({required this.text});
  final String text;
}

class McqDraft extends NewCardDraft {
  const McqDraft({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
  final String question;
  final List<String> options;
  final int correctIndex;
}

abstract class CardRepository {
  Stream<List<FlashCard>> watchCards(String deckId);
  Future<FlashCard> getCard({required String deckId, required String cardId});

  /// Atomically: create the card, then bump the parent deck's
  /// cardCount + updatedAt via a batch write.
  Future<FlashCard> createCard({
    required String deckId,
    required NewCardDraft draft,
  });

  Future<void> updateCard(FlashCard card);

  /// Atomically: delete the card, then decrement parent deck's
  /// cardCount via a batch write.
  Future<void> deleteCard({required String deckId, required String cardId});

  /// Persist a review rating against [cardId] under [deckId].
  /// Computes the next ReviewProgress via FsrsScheduler and writes it back
  /// atomically with a bump of the deck's dueCount aggregate.
  Future<FlashCard> submitReview({
    required String deckId,
    required String cardId,
    required ReviewRating rating,
    required DateTime reviewedAt,
  });
}
