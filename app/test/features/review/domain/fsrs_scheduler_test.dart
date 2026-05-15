import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/review/domain/card_state.dart';
import 'package:zeno/features/review/domain/fsrs_scheduler.dart';
import 'package:zeno/features/review/domain/review_progress.dart';
import 'package:zeno/features/review/domain/review_rating.dart';

void main() {
  const scheduler = FsrsScheduler();
  final now = DateTime.utc(2026, 1, 1, 12);

  // ---------------------------------------------------------------------------
  group('first review — new card', () {
    test('Good rating promotes to review with expected stability', () {
      final next = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      expect(next.state, CardState.review);
      expect(next.reps, 1);
      expect(next.lapses, 0);
      // stability should be w[2] = 3.0412
      expect(next.stability, closeTo(3.0412, 0.01));
      expect(next.due, isNotNull);
      expect(next.lastReview, now);
    });

    test('Again rating promotes to review (V1.1 simplification)', () {
      final next = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.again,
        reviewedAt: now,
      );
      expect(next.state, CardState.review);
      expect(next.reps, 1);
      expect(next.lapses, 0); // no lapse on newCard state
      // stability should be w[0] = 0.4197, clamped to >= 0.1
      expect(next.stability, closeTo(0.4197, 0.01));
      expect(next.due, isNotNull);
    });

    test('Hard rating gives stability ~w[1]', () {
      final next = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.hard,
        reviewedAt: now,
      );
      expect(next.state, CardState.review);
      expect(next.stability, closeTo(1.1869, 0.01));
    });

    test('Easy rating gives stability ~w[3]', () {
      final next = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.easy,
        reviewedAt: now,
      );
      expect(next.state, CardState.review);
      expect(next.stability, closeTo(15.2441, 0.01));
    });

    test('due is set to at least today + 1 day for any rating', () {
      for (final rating in ReviewRating.values) {
        final next = scheduler.schedule(
          current: ReviewProgress.initial(),
          rating: rating,
          reviewedAt: now,
        );
        expect(
          next.due!.isAfter(now),
          isTrue,
          reason: 'due should be after reviewedAt for $rating',
        );
      }
    });

    test('Good initial difficulty is w[4] - 0 * w[5] clamped to [1,10]', () {
      final next = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good, // value=3, offset from 3 = 0
        reviewedAt: now,
      );
      // D = w[4] - (3-3)*w[5] = 7.1434
      expect(next.difficulty, closeTo(7.1434, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  group('monotonicity', () {
    test('successive Good ratings grow the interval', () {
      var p = ReviewProgress.initial();
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      final firstInterval = p.due!.difference(now).inMinutes;

      final secondReview = p.due!;
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.good,
        reviewedAt: secondReview,
      );
      final secondInterval = p.due!.difference(secondReview).inMinutes;

      expect(secondInterval, greaterThan(firstInterval));
    });

    test('successive Easy ratings grow the interval faster than Good', () {
      var pGood = ReviewProgress.initial();
      var pEasy = ReviewProgress.initial();

      pGood = scheduler.schedule(
        current: pGood,
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      pEasy = scheduler.schedule(
        current: pEasy,
        rating: ReviewRating.easy,
        reviewedAt: now,
      );

      // After first review, Easy should have a longer interval than Good.
      final goodDays = pGood.due!.difference(now).inDays;
      final easyDays = pEasy.due!.difference(now).inDays;
      expect(easyDays, greaterThan(goodDays));
    });

    test('three successive Goods show monotonically increasing intervals', () {
      var p = ReviewProgress.initial();
      final intervals = <int>[];

      var reviewTime = now;
      for (var i = 0; i < 3; i++) {
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.good,
          reviewedAt: reviewTime,
        );
        intervals.add(p.due!.difference(reviewTime).inMinutes);
        reviewTime = p.due!;
      }

      for (var i = 1; i < intervals.length; i++) {
        expect(
          intervals[i],
          greaterThan(intervals[i - 1]),
          reason:
              'interval[$i]=${intervals[i]} should > '
              'interval[${i - 1}]=${intervals[i - 1]}',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  group('lapses', () {
    test('Again on review state moves card to relearning', () {
      // First get into review state.
      var p = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      expect(p.state, CardState.review);

      final stabilityBeforeLapse = p.stability;
      final reviewTime = p.due!;

      // Now lapse.
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.again,
        reviewedAt: reviewTime,
      );
      expect(p.state, CardState.relearning);
      expect(p.lapses, 1);
      expect(p.stability, lessThan(stabilityBeforeLapse));
    });

    test('Again on review state increments lapses by 1 each time', () {
      var p = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );

      for (var i = 1; i <= 3; i++) {
        final reviewTime = p.due!;
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.again,
          reviewedAt: reviewTime,
        );
        // After first lapse → relearning; successive agains stay relearning.
        // Lapses should only increment when coming from review state.
        // After i=1 lapses=1; i=2 still relearning so no lapse increment.
        if (i == 1) {
          expect(p.lapses, 1);
          expect(p.state, CardState.relearning);
        } else {
          // Stays relearning, lapses do NOT increment (not coming from review).
          expect(p.lapses, 1);
          expect(p.state, CardState.relearning);
        }
      }
    });

    test('Again then Good on relearning promotes back to review', () {
      var p = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      // Lapse.
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.again,
        reviewedAt: p.due!,
      );
      expect(p.state, CardState.relearning);

      // Recover.
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.good,
        reviewedAt: p.due!,
      );
      expect(p.state, CardState.review);
    });

    test('Again on new card does not increment lapses', () {
      final p = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.again,
        reviewedAt: now,
      );
      expect(p.lapses, 0);
    });
  });

  // ---------------------------------------------------------------------------
  group('null lastReview', () {
    test('schedule with lastReview=null treats elapsed as 0, no exception', () {
      expect(
        () => scheduler.schedule(
          current: ReviewProgress.initial(),
          rating: ReviewRating.good,
          reviewedAt: now,
        ),
        returnsNormally,
      );
    });

    test('initial ReviewProgress has null lastReview', () {
      expect(ReviewProgress.initial().lastReview, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('difficulty clamping', () {
    test('difficulty stays in [1, 10] after 10 repeated Again ratings', () {
      var p = ReviewProgress.initial();
      for (var i = 0; i < 10; i++) {
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.again,
          reviewedAt: now.add(Duration(days: i)),
        );
        expect(p.difficulty, greaterThanOrEqualTo(1.0));
        expect(p.difficulty, lessThanOrEqualTo(10.0));
      }
    });

    test('difficulty stays in [1, 10] after 10 repeated Easy ratings', () {
      var p = ReviewProgress.initial();
      for (var i = 0; i < 10; i++) {
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.easy,
          reviewedAt: now.add(Duration(days: i)),
        );
        expect(p.difficulty, greaterThanOrEqualTo(1.0));
        expect(p.difficulty, lessThanOrEqualTo(10.0));
      }
    });

    test('stability stays >= 0.1 after repeated Again ratings', () {
      var p = ReviewProgress.initial();
      for (var i = 0; i < 10; i++) {
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.again,
          reviewedAt: now.add(Duration(days: i)),
        );
        expect(p.stability, greaterThanOrEqualTo(0.1));
      }
    });
  });

  // ---------------------------------------------------------------------------
  group('purity', () {
    test('same inputs produce identical ReviewProgress outputs', () {
      final input = ReviewProgress.initial();
      final result1 = scheduler.schedule(
        current: input,
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      final result2 = scheduler.schedule(
        current: input,
        rating: ReviewRating.good,
        reviewedAt: now,
      );

      expect(result1, equals(result2));
    });

    test('calling schedule does not mutate the input progress', () {
      final input = ReviewProgress.initial();
      final stateBefore = input.state;
      final repsBefore = input.reps;

      scheduler.schedule(
        current: input,
        rating: ReviewRating.good,
        reviewedAt: now,
      );

      expect(input.state, stateBefore);
      expect(input.reps, repsBefore);
    });

    test('scheduler instance has no mutable state', () {
      const s1 = FsrsScheduler();
      const s2 = FsrsScheduler();

      final r1 = s1.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      final r2 = s2.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );

      expect(r1, equals(r2));
    });
  });

  // ---------------------------------------------------------------------------
  group('state machine', () {
    test('newCard -> review for all ratings (V1.1 simplification)', () {
      for (final rating in ReviewRating.values) {
        final p = scheduler.schedule(
          current: ReviewProgress.initial(),
          rating: rating,
          reviewedAt: now,
        );
        expect(p.state, CardState.review, reason: 'rating=$rating');
      }
    });

    test('review + Hard/Good/Easy stays in review', () {
      final inReview = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      for (final rating in [
        ReviewRating.hard,
        ReviewRating.good,
        ReviewRating.easy,
      ]) {
        final p = scheduler.schedule(
          current: inReview,
          rating: rating,
          reviewedAt: inReview.due!,
        );
        expect(p.state, CardState.review, reason: 'rating=$rating');
      }
    });

    test('relearning + Good -> review', () {
      var p = scheduler.schedule(
        current: ReviewProgress.initial(),
        rating: ReviewRating.good,
        reviewedAt: now,
      );
      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.again,
        reviewedAt: p.due!,
      );
      expect(p.state, CardState.relearning);

      p = scheduler.schedule(
        current: p,
        rating: ReviewRating.good,
        reviewedAt: p.due!,
      );
      expect(p.state, CardState.review);
    });
  });

  // ---------------------------------------------------------------------------
  group('reps counter', () {
    test('reps increments on each schedule call', () {
      var p = ReviewProgress.initial();
      for (var i = 1; i <= 5; i++) {
        p = scheduler.schedule(
          current: p,
          rating: ReviewRating.good,
          reviewedAt: now.add(Duration(days: i)),
        );
        expect(p.reps, i);
      }
    });
  });
}
