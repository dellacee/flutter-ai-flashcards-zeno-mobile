import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/ai/data/ai_api_client.dart';
import 'package:zeno/features/ai/domain/generated_card_draft.dart';

// ---------------------------------------------------------------------------
// Stub HttpClientAdapter — injects fixed ResponseBody without a real server
// ---------------------------------------------------------------------------

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._respond);

  final Future<ResponseBody> Function(RequestOptions) _respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _respond(options);

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Helper — build a Dio that returns a fixed JSON map
// ---------------------------------------------------------------------------

Dio _fakeDio(Map<String, dynamic> payload, {int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = _StubAdapter((_) async => ResponseBody.fromString(
          jsonEncode(payload),
          statusCode,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ));
  return dio;
}

// ---------------------------------------------------------------------------
// Helper — build a Dio that throws a DioException of the given type
// ---------------------------------------------------------------------------

Dio _throwingDio(DioExceptionType exType) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = _StubAdapter((_) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/generate/cards'),
        type: exType,
      );
    });
  return dio;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AiApiClient.generateCards', () {
    test('decodes mixed-type response correctly', () async {
      final dio = _fakeDio({
        'cards': [
          {'type': 'qa', 'front': 'Q1', 'back': 'A1'},
          {'type': 'cloze', 'text': 'X is the {{c1::Y}} of Z'},
          {
            'type': 'mcq',
            'question': 'Q?',
            'options': ['a', 'b'],
            'correct_index': 1,
          },
        ],
        'source_chars': 100,
        'model': 'fake-v1',
      });

      final client = AiApiClient(dio: dio);
      final drafts = await client.generateCards(
        text: 'long enough text to pass any client guard here',
      );

      expect(drafts.length, 3);
      expect(drafts[0], isA<GeneratedQaDraft>());
      expect(drafts[1], isA<GeneratedClozeDraft>());
      expect(drafts[2], isA<GeneratedMcqDraft>());

      final qa = drafts[0] as GeneratedQaDraft;
      expect(qa.front, 'Q1');
      expect(qa.back, 'A1');

      final cloze = drafts[1] as GeneratedClozeDraft;
      expect(cloze.text, 'X is the {{c1::Y}} of Z');

      final mcq = drafts[2] as GeneratedMcqDraft;
      expect(mcq.correctIndex, 1);
    });

    test('translates DioException.connectionError to AppFailure.network',
        () async {
      final client =
          AiApiClient(dio: _throwingDio(DioExceptionType.connectionError));

      await expectLater(
        client.generateCards(text: 'some text long enough for a test run'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f is NetworkFailure,
            'is NetworkFailure',
            isTrue,
          ),
        ),
      );
    });

    test('translates DioException.connectionTimeout to AppFailure.network',
        () async {
      final client =
          AiApiClient(dio: _throwingDio(DioExceptionType.connectionTimeout));

      await expectLater(
        client.generateCards(text: 'some text long enough for a test run'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
