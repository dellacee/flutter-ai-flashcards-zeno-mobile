import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  const factory AppFailure.network({String? message}) = NetworkFailure;
  const factory AppFailure.auth({
    required String code,
    String? message,
  }) = AuthFailure;
  const factory AppFailure.notFound({String? message}) = NotFoundFailure;
  const factory AppFailure.permission({String? message}) = PermissionFailure;
  const factory AppFailure.unknown({String? message, Object? cause}) =
      UnknownFailure;
}
