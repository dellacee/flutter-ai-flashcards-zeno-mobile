import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/settings/data/user_settings_repository.dart';
import 'package:zeno/features/settings/domain/user_settings.dart';

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return FirestoreUserSettingsRepository(
    firestore: FirebaseFirestore.instance,
    auth: fb.FirebaseAuth.instance,
  );
});

final userSettingsProvider = StreamProvider<UserSettings>((ref) {
  return ref.watch(userSettingsRepositoryProvider).watchSettings();
});
