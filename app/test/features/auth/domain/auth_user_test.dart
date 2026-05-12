import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('constructs with required fields', () {
      const user = AuthUser(uid: 'u1', email: 'a@b.com');
      expect(user.uid, 'u1');
      expect(user.email, 'a@b.com');
      expect(user.displayName, isNull);
      expect(user.isAnonymous, isFalse);
    });

    test('equality is value-based', () {
      const a = AuthUser(uid: 'u1', email: 'a@b.com', displayName: 'A');
      const b = AuthUser(uid: 'u1', email: 'a@b.com', displayName: 'A');
      expect(a, equals(b));
    });

    test('copyWith updates fields', () {
      const a = AuthUser(uid: 'u1', email: 'a@b.com');
      final b = a.copyWith(displayName: 'A');
      expect(b.displayName, 'A');
      expect(b.uid, 'u1');
    });
  });
}
