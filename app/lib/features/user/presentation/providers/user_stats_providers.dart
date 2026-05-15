import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/user/data/user_stats_repository.dart';
import 'package:zeno/features/user/domain/user_stats.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return FirestoreUserStatsRepository(
    firestore: FirebaseFirestore.instance,
    auth: fb.FirebaseAuth.instance,
  );
});

final userStatsProvider = StreamProvider<UserStats>((ref) {
  return ref.watch(userStatsRepositoryProvider).watchStats();
});
