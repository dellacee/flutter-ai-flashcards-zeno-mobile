import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/user/domain/streak_calculator.dart';
import 'package:zeno/features/user/domain/user_stats.dart';

void main() {
  const calc = StreakCalculator();
  final monday = DateTime(2026, 5, 11, 10); // Monday 10am local

  test('first review starts streak at 1', () {
    final out = calc.apply(current: const UserStats(), reviewedAt: monday);
    expect(out.streak, 1);
    expect(out.bestStreak, 1);
    expect(out.totalReviews, 1);
    expect(out.lastReviewedDate, '2026-05-11');
  });

  test('second review same day keeps streak', () {
    final after1 = calc.apply(current: const UserStats(), reviewedAt: monday);
    final after2 = calc.apply(
      current: after1,
      reviewedAt: monday.add(const Duration(hours: 2)),
    );
    expect(after2.streak, 1);
    expect(after2.totalReviews, 2);
  });

  test('review next day increments streak', () {
    final after1 = calc.apply(current: const UserStats(), reviewedAt: monday);
    final tuesday = monday.add(const Duration(days: 1));
    final after2 = calc.apply(current: after1, reviewedAt: tuesday);
    expect(after2.streak, 2);
    expect(after2.bestStreak, 2);
  });

  test('review after a 2-day gap resets streak to 1', () {
    final after1 = calc.apply(
      current: const UserStats(
        streak: 5,
        bestStreak: 5,
        totalReviews: 10,
        lastReviewedDate: '2026-05-11',
      ),
      reviewedAt: DateTime(2026, 5, 14),
    );
    expect(after1.streak, 1);
    expect(after1.bestStreak, 5); // unchanged
    expect(after1.totalReviews, 11);
  });

  test('bestStreak only goes up', () {
    var s = const UserStats();
    for (var d = 0; d < 7; d++) {
      s = calc.apply(current: s, reviewedAt: monday.add(Duration(days: d)));
    }
    expect(s.streak, 7);
    expect(s.bestStreak, 7);
    // break streak
    s = calc.apply(
      current: s,
      reviewedAt: monday.add(const Duration(days: 10)),
    );
    expect(s.streak, 1);
    expect(s.bestStreak, 7); // best preserved
  });
}
