import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/settings/data/user_settings_repository.dart';
import 'package:zeno/features/settings/domain/user_settings.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockUser extends Mock implements fb.User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth auth;
  late FirestoreUserSettingsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    repo = FirestoreUserSettingsRepository(firestore: firestore, auth: auth);
  });

  // -------------------------------------------------------------------------
  // 1. updateSettings merges into users/{uid}.settings without clobbering stats
  // -------------------------------------------------------------------------
  test('updateSettings merges settings without clobbering stats sub-map',
      () async {
    // Pre-seed a stats sub-map so we can confirm it survives the merge.
    await firestore.collection('users').doc('u1').set({
      'stats': {
        'streak': 5,
        'bestStreak': 7,
        'totalReviews': 42,
        'lastReviewedDate': '2026-05-14',
      },
    });

    const settings = UserSettings(
      reviewTime: '08:30',
      notificationsEnabled: true,
    );

    await repo.updateSettings(settings);

    final snap = await firestore.collection('users').doc('u1').get();
    final data = snap.data()!;

    // settings sub-map was written
    final settingsMap = data['settings'] as Map<String, dynamic>;
    expect(settingsMap['reviewTime'], '08:30');
    expect(settingsMap['notificationsEnabled'], true);
    expect(settingsMap['dailyNewCardLimit'], 20);
    expect(settingsMap['theme'], 'system');
    expect(settingsMap['locale'], 'vi');

    // stats sub-map was NOT clobbered
    final statsMap = data['stats'] as Map<String, dynamic>;
    expect(statsMap['streak'], 5);
    expect(statsMap['bestStreak'], 7);
    expect(statsMap['totalReviews'], 42);
  });

  // -------------------------------------------------------------------------
  // 2. watchSettings emits defaults when the settings map is missing
  // -------------------------------------------------------------------------
  test('watchSettings emits defaults when settings field is absent', () async {
    // Create user doc with only displayName — no settings field.
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Lý Minh Thư',
    });

    final settings = await repo.watchSettings().first;

    expect(settings, const UserSettings());
    expect(settings.reviewTime, '07:00');
    expect(settings.dailyNewCardLimit, 20);
    expect(settings.theme, 'system');
    expect(settings.locale, 'vi');
    expect(settings.notificationsEnabled, false);
  });

  // -------------------------------------------------------------------------
  // 3. getSettings returns defaults when stats field is missing
  // -------------------------------------------------------------------------
  test(
      'getSettings returns default UserSettings '
      'when settings field is missing',
      () async {
    await firestore.collection('users').doc('u1').set({'displayName': 'Alice'});

    final settings = await repo.getSettings();

    expect(settings, const UserSettings());
  });

  // -------------------------------------------------------------------------
  // 4. watchSettings emits updated settings after updateSettings
  // -------------------------------------------------------------------------
  test('watchSettings emits updated settings after updateSettings', () async {
    await firestore.collection('users').doc('u1').set({
      'settings': {
        'reviewTime': '07:00',
        'dailyNewCardLimit': 20,
        'theme': 'system',
        'locale': 'vi',
        'notificationsEnabled': false,
      },
    });

    // Subscribe before mutation
    final future = repo.watchSettings().skip(1).first;

    await repo.updateSettings(
      const UserSettings(reviewTime: '09:00', notificationsEnabled: true),
    );

    final updated = await future;
    expect(updated.reviewTime, '09:00');
    expect(updated.notificationsEnabled, true);
  });
}
