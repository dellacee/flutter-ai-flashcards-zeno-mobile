import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/notifications/domain/time_of_day_x.dart';
import 'package:zeno/features/notifications/presentation/providers/notification_providers.dart';
import 'package:zeno/features/settings/domain/user_settings.dart';
import 'package:zeno/features/settings/presentation/providers/user_settings_providers.dart';

/// Settings screen — daily review notification toggle + review time picker.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Lỗi tải cài đặt: $err'),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(userSettingsRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    Future<void> persistAndReschedule(UserSettings updated) async {
      await repo.updateSettings(updated);
      if (updated.notificationsEnabled) {
        final time = TimeOfDayX.parse(updated.reviewTime);
        await notifService.scheduleDailyReview(
          hour: time.hour,
          minute: time.minute,
        );
      } else {
        await notifService.cancelDailyReview();
      }
    }

    return ListView(
      children: [
        // -------------------------------------------------------------------
        // Notification toggle
        // -------------------------------------------------------------------
        SwitchListTile(
          title: const Text('Nhắc review hằng ngày'),
          subtitle: const Text('Nhận thông báo nhắc nhở mỗi ngày'),
          value: settings.notificationsEnabled,
          onChanged: (enabled) async {
            if (enabled) {
              final granted = await notifService.requestPermission();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã từ chối quyền thông báo'),
                    ),
                  );
                }
                return;
              }
            }
            final updated =
                settings.copyWith(notificationsEnabled: enabled);
            await persistAndReschedule(updated);
          },
        ),

        // -------------------------------------------------------------------
        // Review time picker
        // -------------------------------------------------------------------
        ListTile(
          title: const Text('Giờ nhắc'),
          subtitle: Text(settings.reviewTime),
          trailing: const Icon(Icons.access_time_outlined),
          onTap: () async {
            final parsed = TimeOfDayX.parse(settings.reviewTime);
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: parsed.hour,
                minute: parsed.minute,
              ),
            );
            if (picked == null) return;
            final newTime = TimeOfDayX.format(
              hour: picked.hour,
              minute: picked.minute,
            );
            final updated = settings.copyWith(reviewTime: newTime);
            await persistAndReschedule(updated);
          },
        ),

        const Divider(),

        // -------------------------------------------------------------------
        // Theme selector (persist only in V1.1; switching wired in V1.2)
        // -------------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giao diện',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'system',
                    label: Text('Hệ thống'),
                  ),
                  ButtonSegment(value: 'light', label: Text('Sáng')),
                  ButtonSegment(value: 'dark', label: Text('Tối')),
                ],
                selected: {settings.theme},
                onSelectionChanged: (selection) async {
                  final updated =
                      settings.copyWith(theme: selection.first);
                  await repo.updateSettings(updated);
                },
              ),
            ],
          ),
        ),

        const Divider(),

        // -------------------------------------------------------------------
        // Footer
        // -------------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Phiên bản 0.2.0 • V1.1',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
