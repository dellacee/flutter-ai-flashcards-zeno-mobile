import 'package:zeno/features/user/domain/user_stats.dart';

class UserStatsDto {
  UserStatsDto._();

  static UserStats fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const UserStats();
    return UserStats(
      streak: (raw['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (raw['bestStreak'] as num?)?.toInt() ?? 0,
      totalReviews: (raw['totalReviews'] as num?)?.toInt() ?? 0,
      lastReviewedDate: raw['lastReviewedDate'] as String?,
    );
  }

  static Map<String, dynamic> toMap(UserStats s) => {
        'streak': s.streak,
        'bestStreak': s.bestStreak,
        'totalReviews': s.totalReviews,
        'lastReviewedDate': s.lastReviewedDate,
      };
}
