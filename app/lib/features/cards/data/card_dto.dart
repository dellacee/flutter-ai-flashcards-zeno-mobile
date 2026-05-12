import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';

class CardDto {
  CardDto._();

  static FlashCard fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    required String deckId,
  }) {
    final d = snap.data() ?? <String, dynamic>{};
    final type = d['type'] as String?;
    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    switch (type) {
      case 'qa':
        return FlashCard.qa(
          id: snap.id,
          deckId: deckId,
          front: d['front'] as String? ?? '',
          back: d['back'] as String? ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      case 'cloze':
        return FlashCard.cloze(
          id: snap.id,
          deckId: deckId,
          text: d['text'] as String? ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      case 'mcq':
        return FlashCard.mcq(
          id: snap.id,
          deckId: deckId,
          question: d['question'] as String? ?? '',
          options: List<String>.from(
            (d['options'] as List<dynamic>?) ?? const <dynamic>[],
          ),
          correctIndex: (d['correctIndex'] as num?)?.toInt() ?? 0,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      default:
        throw AppFailure.unknown(
          message: 'Unknown card type: $type for card ${snap.id}',
        );
    }
  }

  static Map<String, dynamic> toFirestore(FlashCard card) => switch (card) {
        QaCard() => {
            'type': 'qa',
            'front': card.front,
            'back': card.back,
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
        ClozeCard() => {
            'type': 'cloze',
            'text': card.text,
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
        McqCard() => {
            'type': 'mcq',
            'question': card.question,
            'options': card.options,
            'correctIndex': card.correctIndex,
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
      };
}
