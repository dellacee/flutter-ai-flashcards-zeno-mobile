import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('07:00') String reviewTime,
    @Default(20) int dailyNewCardLimit,
    @Default('system') String theme,
    @Default('vi') String locale,
    @Default(false) bool notificationsEnabled,
  }) = _UserSettings;
}
