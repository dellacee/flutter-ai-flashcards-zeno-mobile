import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated_card_draft.freezed.dart';

@freezed
sealed class GeneratedCardDraft with _$GeneratedCardDraft {
  const factory GeneratedCardDraft.qa({
    required String front,
    required String back,
  }) = GeneratedQaDraft;

  const factory GeneratedCardDraft.cloze({
    required String text,
  }) = GeneratedClozeDraft;

  const factory GeneratedCardDraft.mcq({
    required String question,
    required List<String> options,
    required int correctIndex,
  }) = GeneratedMcqDraft;

  factory GeneratedCardDraft.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'qa':
        return GeneratedCardDraft.qa(
          front: json['front'] as String,
          back: json['back'] as String,
        );
      case 'cloze':
        return GeneratedCardDraft.cloze(text: json['text'] as String);
      case 'mcq':
        return GeneratedCardDraft.mcq(
          question: json['question'] as String,
          options: List<String>.from(json['options'] as List<dynamic>),
          correctIndex: json['correct_index'] as int,
        );
      default:
        throw FormatException('Unknown card type: ${json['type']}');
    }
  }
}
