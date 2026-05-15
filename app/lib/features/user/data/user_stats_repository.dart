import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/user/data/user_stats_dto.dart';
import 'package:zeno/features/user/domain/streak_calculator.dart';
import 'package:zeno/features/user/domain/user_stats.dart';

abstract class UserStatsRepository {
  Stream<UserStats> watchStats();
  Future<UserStats> getStats();
  Future<UserStats> applyReview({required DateTime reviewedAt});
}

class FirestoreUserStatsRepository implements UserStatsRepository {
  FirestoreUserStatsRepository({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
    StreakCalculator calculator = const StreakCalculator(),
  })  : _firestore = firestore,
        _auth = auth,
        _calculator = calculator;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final StreakCalculator _calculator;

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
  Stream<UserStats> watchStats() {
    return _userDoc.snapshots().map(
          (snap) => UserStatsDto.fromMap(
            snap.data()?['stats'] as Map<String, dynamic>?,
          ),
        );
  }

  @override
  Future<UserStats> getStats() async {
    final snap = await _userDoc.get();
    return UserStatsDto.fromMap(
      snap.data()?['stats'] as Map<String, dynamic>?,
    );
  }

  @override
  Future<UserStats> applyReview({required DateTime reviewedAt}) async {
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(_userDoc);
      final current = UserStatsDto.fromMap(
        snap.data()?['stats'] as Map<String, dynamic>?,
      );
      final next = _calculator.apply(current: current, reviewedAt: reviewedAt);
      tx.set(
        _userDoc,
        {'stats': UserStatsDto.toMap(next)},
        SetOptions(merge: true),
      );
      return next;
    });
  }
}
