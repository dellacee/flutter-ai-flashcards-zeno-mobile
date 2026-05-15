import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:zeno/core/logger/app_logger.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _log = appLog('notifications.service');

  static const _channelId = 'zeno_daily_review';
  static const _channelName = 'Daily review reminder';
  static const _channelDesc = 'Daily reminder to review cards';
  static const _notifId = 1;

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    // Set local timezone — flutter_timezone would be nicer but adds another
    // dep. For V1.1, use the JVM's local timezone via
    // DateTime.now().timeZoneName best-effort.
    try {
      tz.setLocalLocation(
        tz.getLocation(DateTime.now().timeZoneName),
      );
    } catch (_) {
      // Fall back to Asia/Ho_Chi_Minh (project default user base)
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);
    _initialised = true;
  }

  /// Asks the user for the POST_NOTIFICATIONS permission (Android 13+).
  /// Returns `true` if granted (or already granted, or on older Android).
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Schedule a daily notification at [hour]:[minute] local time.
  /// Cancels any existing schedule first.
  Future<void> scheduleDailyReview({
    required int hour,
    required int minute,
  }) async {
    await init();
    await _plugin.cancel(_notifId);
    final scheduled = _nextInstanceOf(hour, minute);
    await _plugin.zonedSchedule(
      _notifId,
      'Đến giờ học rồi 🎓',
      'Mở Zeno để review card hôm nay.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // daily repeat
    );
    _log.info(
      'Daily review notification scheduled for $hour:$minute local',
    );
  }

  Future<void> cancelDailyReview() async {
    await init();
    await _plugin.cancel(_notifId);
    _log.info('Daily review notification cancelled');
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
