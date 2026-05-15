import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:zeno/features/review/domain/card_state.dart';

part 'review_progress.freezed.dart';

@freezed
class ReviewProgress with _$ReviewProgress {
  const factory ReviewProgress({
    /// FSRS stability (days). 0 for never-reviewed cards.
    @Default(0) double stability,

    /// FSRS difficulty (1..10). 0 for never-reviewed cards.
    @Default(0) double difficulty,

    /// When the card should be shown next (UTC).
    DateTime? due,

    /// When the card was last reviewed (UTC). Null if never reviewed.
    DateTime? lastReview,

    /// How many times the card has been reviewed.
    @Default(0) int reps,

    /// How many times the user rated this card Again after promotion to review.
    @Default(0) int lapses,

    @Default(CardState.newCard) CardState state,
  }) = _ReviewProgress;

  factory ReviewProgress.initial() => const ReviewProgress();
}
