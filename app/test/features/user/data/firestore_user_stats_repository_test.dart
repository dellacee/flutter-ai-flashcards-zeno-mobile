import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeno/features/user/data/user_stats_repository.dart';
import 'package:zeno/features/user/domain/user_stats.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockUser extends Mock implements fb.User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth auth;
  late FirestoreUserStatsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    repo = FirestoreUserStatsRepository(firestore: firestore, auth: auth);
  });

  // ---------------------------------------------------------------------------
  // 1. applyReview creates stats subdoc on first review
  // ---------------------------------------------------------------------------
  test('applyReview creates stats subdoc when user has no existing stats',
      () async {
    // User doc starts empty (no stats field)
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Test User',
    });

    final result = await repo.applyReview(
      reviewedAt: DateTime(2026, 5, 11, 10),
    );

    expect(result.streak, 1);
    expect(result.bestStreak, 1);
    expect(result.totalReviews, 1);
    expect(result.lastReviewedDate, '2026-05-11');

    // Verify Firestore was updated
    final snap = await firestore.collection('users').doc('u1').get();
    final stats = snap.data()?['stats'] as Map<String, dynamic>?;
    expect(stats, isNotNull);
    expect(stats!['streak'], 1);
    expect(stats['bestStreak'], 1);
    expect(stats['totalReviews'], 1);
    expect(stats['lastReviewedDate'], '2026-05-11');
  });

  // ---------------------------------------------------------------------------
  // 2. applyReview increments streak across two consecutive days
  // ---------------------------------------------------------------------------
  test('applyReview increments streak when reviewed on consecutive days',
      () async {
    // Seed existing stats for Monday review
    await firestore.collection('users').doc('u1').set({
      'stats': {
        'streak': 1,
        'bestStreak': 1,
        'totalReviews': 1,
        'lastReviewedDate': '2026-05-11',
      },
    });

    // Review on Tuesday
    final result = await repo.applyReview(
      reviewedAt: DateTime(2026, 5, 12, 9, 30),
    );

    expect(result.streak, 2);
    expect(result.bestStreak, 2);
    expect(result.totalReviews, 2);
    expect(result.lastReviewedDate, '2026-05-12');

    // Verify persisted
    final snap = await firestore.collection('users').doc('u1').get();
    final stats = snap.data()?['stats'] as Map<String, dynamic>?;
    expect(stats!['streak'], 2);
    expect(stats['bestStreak'], 2);
    expect(stats['totalReviews'], 2);
    expect(stats['lastReviewedDate'], '2026-05-12');
  });

  // ---------------------------------------------------------------------------
  // 3. watchStats emits updated stats after applyReview
  // ---------------------------------------------------------------------------
  test('watchStats emits updated UserStats after applyReview', () async {
    await firestore.collection('users').doc('u1').set({
      'stats': {
        'streak': 0,
        'bestStreak': 0,
        'totalReviews': 0,
        'lastReviewedDate': null,
      },
    });

    // Subscribe before mutation
    final future = repo.watchStats().skip(1).first;

    await repo.applyReview(reviewedAt: DateTime(2026, 5, 13, 8));

    final stats = await future;
    expect(stats.streak, 1);
    expect(stats.totalReviews, 1);
  });

  // ---------------------------------------------------------------------------
  // 4. getStats returns defaults when stats field is missing
  // ---------------------------------------------------------------------------
  test('getStats returns default UserStats when stats field is missing',
      () async {
    await firestore.collection('users').doc('u1').set({'displayName': 'Alice'});

    final stats = await repo.getStats();

    expect(stats, const UserStats());
  });
}
