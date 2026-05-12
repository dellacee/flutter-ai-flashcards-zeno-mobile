import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/core/error/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure constructs with optional message', () {
      const failure = AppFailure.network(message: 'no internet');
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).message, 'no internet');
    });

    test('NetworkFailure constructs without message', () {
      const failure = AppFailure.network();
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).message, isNull);
    });

    test('AuthFailure constructs with required code', () {
      const failure = AppFailure.auth(
        code: 'user-not-found',
        message: 'No such user',
      );
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).code, 'user-not-found');
      expect(failure.message, 'No such user');
    });

    test('NotFoundFailure constructs correctly', () {
      const failure = AppFailure.notFound(message: 'Resource missing');
      expect(failure, isA<NotFoundFailure>());
    });

    test('PermissionFailure constructs correctly', () {
      const failure = AppFailure.permission(message: 'Access denied');
      expect(failure, isA<PermissionFailure>());
    });

    test('UnknownFailure constructs with cause', () {
      const cause = 'some error object';
      const failure = AppFailure.unknown(message: 'oops', cause: cause);
      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).cause, cause);
    });

    test('sealed switch exhaustively matches every variant', () {
      String label(AppFailure failure) => switch (failure) {
            NetworkFailure() => 'network',
            AuthFailure() => 'auth',
            NotFoundFailure() => 'notFound',
            PermissionFailure() => 'permission',
            UnknownFailure() => 'unknown',
          };

      expect(label(const AppFailure.network()), 'network');
      expect(label(const AppFailure.auth(code: 'x')), 'auth');
      expect(label(const AppFailure.notFound()), 'notFound');
      expect(label(const AppFailure.permission()), 'permission');
      expect(label(const AppFailure.unknown()), 'unknown');
    });

    test('equality holds for same-variant same-args instances', () {
      expect(
        const AppFailure.network(),
        equals(const AppFailure.network()),
      );
      expect(
        const AppFailure.auth(code: 'abc'),
        equals(const AppFailure.auth(code: 'abc')),
      );
    });

    test('inequality holds across different variants', () {
      expect(
        const AppFailure.network(),
        isNot(equals(const AppFailure.unknown())),
      );
    });
  });
}
