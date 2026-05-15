import 'package:intl/intl.dart';
import 'package:zeno/features/user/domain/user_stats.dart';

class StreakCalculator {
  const StreakCalculator();

  /// Returns the updated stats after a review at [reviewedAt].
  /// All date math uses LOCAL timezone.
  UserStats apply({required UserStats current, required DateTime reviewedAt}) {
    final today = _formatLocal(reviewedAt);
    final lastDate = current.lastReviewedDate;

    int newStreak;
    if (lastDate == null) {
      newStreak = 1;
    } else if (lastDate == today) {
      newStreak = current.streak;
    } else {
      final yesterday = _formatLocal(
        reviewedAt.subtract(const Duration(days: 1)),
      );
      newStreak = lastDate == yesterday ? current.streak + 1 : 1;
    }

    final bestStreak =
        newStreak > current.bestStreak ? newStreak : current.bestStreak;

    return current.copyWith(
      streak: newStreak,
      bestStreak: bestStreak,
      totalReviews: current.totalReviews + 1,
      lastReviewedDate: today,
    );
  }

  String _formatLocal(DateTime dt) =>
      DateFormat('yyyy-MM-dd').format(dt.toLocal());
}
