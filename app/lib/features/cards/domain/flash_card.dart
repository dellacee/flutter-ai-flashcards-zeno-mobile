import 'package:freezed_annotation/freezed_annotation.dart';

part 'flash_card.freezed.dart';

@freezed
sealed class FlashCard with _$FlashCard {
  const factory FlashCard.qa({
    required String id,
    required String deckId,
    required String front,
    required String back,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = QaCard;

  const factory FlashCard.cloze({
    required String id,
    required String deckId,
    required String text,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = ClozeCard;

  const factory FlashCard.mcq({
    required String id,
    required String deckId,
    required String question,
    required List<String> options,
    required int correctIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = McqCard;
}
