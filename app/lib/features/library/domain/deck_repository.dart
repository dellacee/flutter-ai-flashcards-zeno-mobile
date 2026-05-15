import 'package:zeno/features/library/domain/deck.dart';

abstract class DeckRepository {
  /// Emit the list of decks for the signed-in user, ordered by updatedAt desc.
  Stream<List<Deck>> watchDecks();

  /// Fetch a single deck by id. Throws notFound failure if missing.
  Future<Deck> getDeck(String id);

  /// Create a new deck under the signed-in user.
  /// Throws auth failure if no current user.
  Future<Deck> createDeck({
    required String title,
    String? description,
    List<String> tags = const [],
    String coverColor = 'indigo',
  });

  /// Update an existing deck. Always bumps updatedAt to now.
  Future<void> updateDeck(Deck deck);

  /// Permanently delete a deck (cards subcollection cleanup is handled by a
  /// future cloud function — out of scope for V1.0).
  Future<void> deleteDeck(String id);

  /// Server-side recount of due cards for a deck (used to keep dueCount fresh).
  /// Counts cards where state == newCard OR due <= now.
  Future<int> recountDue({required String deckId, required DateTime asOf});
}
