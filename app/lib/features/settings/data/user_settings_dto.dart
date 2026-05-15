import 'package:zeno/features/settings/domain/user_settings.dart';

class UserSettingsDto {
  UserSettingsDto._();

  static UserSettings fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const UserSettings();
    return UserSettings(
      reviewTime: raw['reviewTime'] as String? ?? '07:00',
      dailyNewCardLimit: (raw['dailyNewCardLimit'] as num?)?.toInt() ?? 20,
      theme: raw['theme'] as String? ?? 'system',
      locale: raw['locale'] as String? ?? 'vi',
      notificationsEnabled: raw['notificationsEnabled'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> toMap(UserSettings s) => {
        'reviewTime': s.reviewTime,
        'dailyNewCardLimit': s.dailyNewCardLimit,
        'theme': s.theme,
        'locale': s.locale,
        'notificationsEnabled': s.notificationsEnabled,
      };
}
