import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zeno/features/review/domain/review_progress.dart';

part 'flash_card.freezed.dart';

const _initialProgress = ReviewProgress();

@freezed
sealed class FlashCard with _$FlashCard {
  const factory FlashCard.qa({
    required String id,
    required String deckId,
    required String front,
    required String back,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(_initialProgress) ReviewProgress progress,
  }) = QaCard;

  const factory FlashCard.cloze({
    required String id,
    required String deckId,
    required String text,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(_initialProgress) ReviewProgress progress,
  }) = ClozeCard;

  const factory FlashCard.mcq({
    required String id,
    required String deckId,
    required String question,
    required List<String> options,
    required int correctIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(_initialProgress) ReviewProgress progress,
  }) = McqCard;
}

extension FlashCardX on FlashCard {
  ReviewProgress get progress => switch (this) {
        QaCard(progress: final p) => p,
        ClozeCard(progress: final p) => p,
        McqCard(progress: final p) => p,
      };

  String get id => switch (this) {
        QaCard(id: final v) => v,
        ClozeCard(id: final v) => v,
        McqCard(id: final v) => v,
      };

  String get deckId => switch (this) {
        QaCard(deckId: final v) => v,
        ClozeCard(deckId: final v) => v,
        McqCard(deckId: final v) => v,
      };

  /// Returns a copy of this card with the supplied [newProgress].
  FlashCard copyWithProgress(ReviewProgress newProgress) => switch (this) {
        QaCard() => (this as QaCard).copyWith(progress: newProgress),
        ClozeCard() => (this as ClozeCard).copyWith(progress: newProgress),
        McqCard() => (this as McqCard).copyWith(progress: newProgress),
      };
}
