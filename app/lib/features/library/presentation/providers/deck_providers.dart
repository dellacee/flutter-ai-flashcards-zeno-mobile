import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/library/data/firestore_deck_repository.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/domain/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return FirestoreDeckRepository(
    firestore: FirebaseFirestore.instance,
    auth: fb.FirebaseAuth.instance,
  );
});

final deckListProvider = StreamProvider<List<Deck>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDecks();
});

final deckByIdProvider = FutureProvider.family<Deck, String>((ref, id) async {
  return ref.watch(deckRepositoryProvider).getDeck(id);
});
