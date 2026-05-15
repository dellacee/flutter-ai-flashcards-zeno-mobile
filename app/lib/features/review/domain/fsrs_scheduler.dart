import 'dart:math' as math;

import 'package:zeno/features/review/domain/card_state.dart';
import 'package:zeno/features/review/domain/review_progress.dart';
import 'package:zeno/features/review/domain/review_rating.dart';

/// FSRS-4.5 parameters (w0..w18).
const List<double> _w = [
  0.4197, 1.1869, 3.0412, 15.2441, 7.1434, 0.6477, 1.0007, 0.0674,
  1.6597, 0.1712, 1.1178, 2.0225, 0.0904, 0.3025, 2.1214, 0.2498,
  2.9466, 0.4891, 0.6468,
];

/// Maximum interval in days (100 years).
const double _maximumInterval = 36500;

/// FSRS-4.5 spaced repetition scheduler — pure functions, no side effects.
///
/// ## V1.1 simplifications (see full FSRS-4.5 spec for V2):
/// - Multi-step learning queue (1 min / 10 min / 1 day) is omitted.
///   All post-first-review cards are treated as [CardState.review].
/// - No per-user parameter optimisation (w is a constant).
/// - Interval is derived from stability directly
///   (S ≈ days until 90% retention).
///
/// Despite these simplifications the implementation:
/// - Is deterministic and stateless given inputs.
/// - Produces monotonically increasing intervals for successive
///   [ReviewRating.good]/[ReviewRating.easy] answers.
/// - Drops the interval significantly on [ReviewRating.again].
/// - Roughly matches Anki's scheduling behaviour for typical use.
class FsrsScheduler {
  const FsrsScheduler();

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Compute the next [ReviewProgress] after a [rating] given at [reviewedAt].
  ReviewProgress schedule({
    required ReviewProgress current,
    required ReviewRating rating,
    required DateTime reviewedAt,
  }) {
    final elapsedDays = _elapsedDays(current.lastReview, reviewedAt);

    double stability;
    double difficulty;

    if (current.state == CardState.newCard) {
      // First-ever review — use initialisation formulas.
      stability = _initStability(rating);
      difficulty = _initDifficulty(rating);
    } else if (rating == ReviewRating.again) {
      difficulty = _nextDifficulty(current.difficulty, rating);
      stability = _nextStabilityAfterLapse(
        current.copyWith(difficulty: difficulty),
        elapsedDays,
      );
    } else {
      difficulty = _nextDifficulty(current.difficulty, rating);
      stability = _nextStability(
        current.copyWith(difficulty: difficulty),
        rating,
        elapsedDays,
      );
    }

    // Clamp stability to a sensible minimum.
    stability = stability.clamp(0.1, _maximumInterval);

    final nextState = _transition(current.state, rating);

    // Full FSRS interval for review state; 1-day step for learning/relearning.
    final intervalDays =
        nextState == CardState.review ? _nextInterval(stability) : 1;

    final due = reviewedAt.add(Duration(days: intervalDays));

    final incrementLapse =
        rating == ReviewRating.again && current.state == CardState.review;

    return current.copyWith(
      stability: stability,
      difficulty: difficulty,
      due: due,
      lastReview: reviewedAt,
      reps: current.reps + 1,
      lapses: current.lapses + (incrementLapse ? 1 : 0),
      state: nextState,
    );
  }

  // -------------------------------------------------------------------------
  // Initialisation helpers (first review)
  // -------------------------------------------------------------------------

  /// Initial stability for [rating] on a brand-new card.
  double _initStability(ReviewRating rating) {
    final s = switch (rating) {
      ReviewRating.again => _w[0],
      ReviewRating.hard => _w[1],
      ReviewRating.good => _w[2],
      ReviewRating.easy => _w[3],
    };
    return s.clamp(0.1, _maximumInterval);
  }

  /// Initial difficulty for [rating] on a brand-new card.
  double _initDifficulty(ReviewRating rating) {
    final d = _w[4] - (rating.value - 3) * _w[5];
    return d.clamp(1.0, 10.0);
  }

  // -------------------------------------------------------------------------
  // Update helpers (subsequent reviews)
  // -------------------------------------------------------------------------

  /// Mean-reverting difficulty update.
  double _nextDifficulty(double currentDifficulty, ReviewRating rating) {
    final dPrime = currentDifficulty - _w[6] * (rating.value - 3);
    final dDoublePrime = _w[7] * _w[4] + (1 - _w[7]) * dPrime;
    return dDoublePrime.clamp(1.0, 10.0);
  }

  /// Retrievability: recall probability after [elapsedDays] with [stability].
  double _retrievability(double elapsedDays, double stability) {
    return math.pow(1 + elapsedDays / (9 * stability), -1).toDouble();
  }

  /// New stability after a successful recall (Hard / Good / Easy).
  double _nextStability(
    ReviewProgress current,
    ReviewRating rating,
    double elapsedDays,
  ) {
    final r = _retrievability(elapsedDays, current.stability);
    final hardPenalty = rating == ReviewRating.hard ? _w[15] : 1.0;
    final easyBonus = rating == ReviewRating.easy ? _w[16] : 1.0;

    final sPrime = current.stability *
        (1 +
            math.exp(_w[8]) *
                (11 - current.difficulty) *
                math.pow(current.stability, -_w[9]) *
                (math.exp((1 - r) * _w[10]) - 1) *
                hardPenalty *
                easyBonus);

    return sPrime.clamp(0.1, _maximumInterval);
  }

  /// New stability after a lapse (Again rating on a review card).
  double _nextStabilityAfterLapse(
    ReviewProgress current,
    double elapsedDays,
  ) {
    final r = _retrievability(elapsedDays, current.stability);
    final sLapse = _w[11] *
        math.pow(current.difficulty, -_w[12]) *
        (math.pow(current.stability + 1, _w[13]) - 1) *
        math.exp((1 - r) * _w[14]);

    return sLapse.clamp(0.1, _maximumInterval);
  }

  // -------------------------------------------------------------------------
  // Interval
  // -------------------------------------------------------------------------

  /// Convert stability (days) to a scheduled interval in days.
  ///
  /// For V1.1 we use: interval ≈ stability, which approximates the
  /// standard FSRS formula at the target 90% retention closely enough.
  int _nextInterval(double stability) {
    final raw = stability.clamp(1.0, _maximumInterval);
    return raw.round();
  }

  // -------------------------------------------------------------------------
  // State machine
  // -------------------------------------------------------------------------

  /// Determine next [CardState] after [rating] from [current].
  ///
  /// V1.1 simplification: skip multi-step learning queue — any card that
  /// completes its first review enters [CardState.review] immediately.
  CardState _transition(CardState current, ReviewRating rating) {
    return switch (current) {
      CardState.newCard => CardState.review,
      CardState.learning => CardState.review,
      CardState.review =>
        rating == ReviewRating.again ? CardState.relearning : CardState.review,
      CardState.relearning =>
        rating == ReviewRating.again ? CardState.relearning : CardState.review,
    };
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  /// Elapsed time in days between [lastReview] and [reviewedAt].
  /// Returns 0 if [lastReview] is null or review is in the past.
  double _elapsedDays(DateTime? lastReview, DateTime reviewedAt) {
    if (lastReview == null) return 0;
    final minutes = reviewedAt.difference(lastReview).inMinutes;
    return (minutes / (60 * 24)).clamp(0, _maximumInterval);
  }
}
