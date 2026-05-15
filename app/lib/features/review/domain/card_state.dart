/// Lifecycle of a card in the scheduler.
enum CardState {
  /// Never reviewed.
  newCard,

  /// First time being learned, ratings drive promotion to [review].
  learning,

  /// Promoted out of learning; lapses send it back through learning.
  review,

  /// Was in review but answered Again; relearning until promoted back.
  relearning,
}
