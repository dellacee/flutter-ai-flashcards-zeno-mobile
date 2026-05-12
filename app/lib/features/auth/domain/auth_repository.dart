import 'package:zeno/features/auth/domain/auth_user.dart';

abstract class AuthRepository {
  /// Emits the current [AuthUser] (or null when signed out) whenever
  /// the underlying auth state changes.
  Stream<AuthUser?> authStateChanges();

  /// Synchronous view of the currently signed-in user, if any.
  AuthUser? get currentUser;

  /// Opens the Google account picker and signs in.
  /// Throws an auth failure if the user cancels or authentication fails.
  Future<AuthUser> signInWithGoogle();

  /// Sign in with email + password.
  /// Throws an auth failure on wrong-password / user-not-found / etc.
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email + password.
  /// Throws an auth failure on email-already-in-use / weak-password / etc.
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  });

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out from both Firebase and Google.
  Future<void> signOut();

  /// Permanently delete the signed-in user. Required for Play / App Store policy.
  Future<void> deleteAccount();
}
