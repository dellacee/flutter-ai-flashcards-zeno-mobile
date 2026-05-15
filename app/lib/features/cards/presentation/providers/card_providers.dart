import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/cards/data/firestore_card_repository.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/domain/flash_card.dart';
import 'package:zeno/features/user/presentation/providers/user_stats_providers.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return FirestoreCardRepository(
    firestore: FirebaseFirestore.instance,
    auth: fb.FirebaseAuth.instance,
    statsRepository: ref.watch(userStatsRepositoryProvider),
  );
});

final cardListProvider =
    StreamProvider.family<List<FlashCard>, String>((ref, deckId) {
  return ref.watch(cardRepositoryProvider).watchCards(deckId);
});

final cardByIdProvider = FutureProvider.family<FlashCard,
    ({String deckId, String cardId})>((ref, ids) async {
  return ref
      .watch(cardRepositoryProvider)
      .getCard(deckId: ids.deckId, cardId: ids.cardId);
});
