import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/review/domain/card_state.dart';
import 'package:zeno/features/review/domain/review_progress.dart';

class CardDto {
  CardDto._();

  static ReviewProgress _progressFromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const ReviewProgress();
    return ReviewProgress(
      stability: (raw['stability'] as num?)?.toDouble() ?? 0,
      difficulty: (raw['difficulty'] as num?)?.toDouble() ?? 0,
      due: (raw['due'] as Timestamp?)?.toDate(),
      lastReview: (raw['lastReview'] as Timestamp?)?.toDate(),
      reps: (raw['reps'] as num?)?.toInt() ?? 0,
      lapses: (raw['lapses'] as num?)?.toInt() ?? 0,
      state: CardState.values.firstWhere(
        (s) => s.name == raw['state'],
        orElse: () => CardState.newCard,
      ),
    );
  }

  static Map<String, dynamic> _progressToMap(ReviewProgress p) => {
        'stability': p.stability,
        'difficulty': p.difficulty,
        'due': p.due == null ? null : Timestamp.fromDate(p.due!),
        'lastReview':
            p.lastReview == null ? null : Timestamp.fromDate(p.lastReview!),
        'reps': p.reps,
        'lapses': p.lapses,
        'state': p.state.name,
      };

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
    final progress = _progressFromMap(d['progress'] as Map<String, dynamic>?);

    switch (type) {
      case 'qa':
        return FlashCard.qa(
          id: snap.id,
          deckId: deckId,
          front: d['front'] as String? ?? '',
          back: d['back'] as String? ?? '',
          progress: progress,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      case 'cloze':
        return FlashCard.cloze(
          id: snap.id,
          deckId: deckId,
          text: d['text'] as String? ?? '',
          progress: progress,
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
          progress: progress,
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
            'progress': _progressToMap(card.progress),
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
        ClozeCard() => {
            'type': 'cloze',
            'text': card.text,
            'progress': _progressToMap(card.progress),
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
        McqCard() => {
            'type': 'mcq',
            'question': card.question,
            'options': card.options,
            'correctIndex': card.correctIndex,
            'progress': _progressToMap(card.progress),
            'createdAt': Timestamp.fromDate(card.createdAt),
            'updatedAt': Timestamp.fromDate(card.updatedAt),
          },
      };
}
