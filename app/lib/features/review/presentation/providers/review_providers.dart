import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/cards/data/card_dto.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';
import 'package:zeno/features/review/domain/card_state.dart';

/// Cards from a deck that are due now (newCard OR due <= now).
final dueCardsProvider =
    FutureProvider.family<List<FlashCard>, String>((ref, deckId) async {
  final repo = ref.watch(cardRepositoryProvider);
  final all = await repo.watchCards(deckId).first;
  final now = DateTime.now();
  return all.where((c) {
    final p = c.progress;
    return p.state == CardState.newCard ||
        (p.due != null && !p.due!.isAfter(now));
  }).toList();
});

/// Cards due across ALL decks for the current user. Used by the Review tab.
final dueCardsAllProvider = FutureProvider<List<FlashCard>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final auth = fb.FirebaseAuth.instance;
  final uid = auth.currentUser?.uid;
  if (uid == null) return [];

  final now = Timestamp.now();
  final newCards = await firestore
      .collectionGroup('cards')
      .where('progress.state', isEqualTo: 'newCard')
      .get();
  final dueCards = await firestore
      .collectionGroup('cards')
      .where('progress.due', isLessThanOrEqualTo: now)
      .get();

  final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  for (final d in [...newCards.docs, ...dueCards.docs]) {
    // Filter to this user's data only.
    if (d.reference.path.startsWith('users/$uid/')) {
      docs[d.id] = d;
    }
  }

  return docs.values.map((doc) {
    final deckId = doc.reference.parent.parent!.id;
    return CardDto.fromFirestore(doc, deckId: deckId);
  }).toList();
});
