import 'package:dio/dio.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/logger/app_logger.dart';
import 'package:zeno/features/ai/domain/generated_card_draft.dart';

class AiApiClient {
  AiApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? _defaultBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ));

  /// Android emulator -> host loopback. Update for physical device or prod.
  static const _defaultBaseUrl = 'http://10.0.2.2:8000';

  final Dio _dio;
  final _log = appLog('ai.api_client');

  Future<List<GeneratedCardDraft>> generateCards({
    required String text,
    int count = 10,
    List<String> cardTypes = const ['qa', 'cloze', 'mcq'],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/generate/cards',
        data: {
          'text': text,
          'count': count,
          'card_types': cardTypes,
        },
      );
      final body = response.data!;
      final raw = body['cards'] as List<dynamic>;
      return raw
          .map((e) => GeneratedCardDraft.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      _log.warning('generateCards failed', e, st);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AppFailure.network(
          message: 'Không kết nối được server AI. Đảm bảo backend đang chạy.',
        );
      }
      throw AppFailure.unknown(
        message: 'Tạo card thất bại: ${e.message}',
        cause: e,
      );
    }
  }
}
