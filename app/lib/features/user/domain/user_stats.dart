import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int streak,
    @Default(0) int bestStreak,
    @Default(0) int totalReviews,

    /// `YYYY-MM-DD` in local time. Null means never reviewed.
    String? lastReviewedDate,
  }) = _UserStats;

  factory UserStats.initial() => const UserStats();
}
