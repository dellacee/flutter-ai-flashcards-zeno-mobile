import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/settings/data/user_settings_dto.dart';
import 'package:zeno/features/settings/domain/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSettings(UserSettings settings);
}

class FirestoreUserSettingsRepository implements UserSettingsRepository {
  FirestoreUserSettingsRepository({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppFailure.auth(
        code: 'no-current-user',
        message: 'Bạn cần đăng nhập.',
      );
    }
    return _firestore.collection('users').doc(uid);
  }

  @override
  Stream<UserSettings> watchSettings() {
    return _userDoc.snapshots().map(
          (snap) => UserSettingsDto.fromMap(
            snap.data()?['settings'] as Map<String, dynamic>?,
          ),
        );
  }

  @override
  Future<UserSettings> getSettings() async {
    final snap = await _userDoc.get();
    return UserSettingsDto.fromMap(
      snap.data()?['settings'] as Map<String, dynamic>?,
    );
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await _userDoc.set(
      {'settings': UserSettingsDto.toMap(settings)},
      SetOptions(merge: true),
    );
  }
}
