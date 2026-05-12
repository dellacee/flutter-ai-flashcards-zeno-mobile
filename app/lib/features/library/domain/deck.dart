import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck.freezed.dart';

@freezed
class Deck with _$Deck {
  const factory Deck({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
    @Default(<String>[]) List<String> tags,
    @Default('indigo') String coverColor,
    @Default(0) int cardCount,
    @Default(0) int dueCount,
  }) = _Deck;
}
