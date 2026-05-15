/// FSRS rating: the user's self-reported recall quality after seeing a card.
enum ReviewRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const ReviewRating(this.value);
  final int value;
}
