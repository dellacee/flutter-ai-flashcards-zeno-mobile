import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/logger/app_logger.dart';
import 'package:zeno/features/auth/domain/auth_repository.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required fb.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final _log = appLog('auth');

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  AuthUser? _mapUser(fb.User? u) {
    if (u == null) return null;
    return AuthUser(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName,
      photoUrl: u.photoURL,
      isAnonymous: u.isAnonymous,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppFailure.auth(
          code: 'cancelled',
          message: 'User cancelled sign-in',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = _mapUser(result.user)!;
      await _bootstrapUserDoc(result.user!);
      return user;
    } on AppFailure {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      _log.warning('signInWithGoogle FirebaseAuthException: ${e.code}', e);
      throw AppFailure.auth(code: e.code, message: e.message);
    } catch (e, st) {
      _log.severe('signInWithGoogle unknown error', e, st);
      throw AppFailure.unknown(message: 'Google sign-in failed', cause: e);
    }
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _mapUser(result.user)!;
      await _bootstrapUserDoc(result.user!);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _log.warning('signInWithEmail FirebaseAuthException: ${e.code}', e);
      throw AppFailure.auth(code: e.code, message: e.message);
    } catch (e, st) {
      _log.severe('signInWithEmail unknown error', e, st);
      throw AppFailure.unknown(message: 'Email sign-in failed', cause: e);
    }
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _mapUser(result.user)!;
      await _bootstrapUserDoc(result.user!);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _log.warning('registerWithEmail FirebaseAuthException: ${e.code}', e);
      throw AppFailure.auth(code: e.code, message: e.message);
    } catch (e, st) {
      _log.severe('registerWithEmail unknown error', e, st);
      throw AppFailure.unknown(message: 'Email registration failed', cause: e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      _log.warning(
        'sendPasswordResetEmail FirebaseAuthException: ${e.code}',
        e,
      );
      throw AppFailure.auth(code: e.code, message: e.message);
    } catch (e, st) {
      _log.severe('sendPasswordResetEmail unknown error', e, st);
      throw AppFailure.unknown(
        message: 'Failed to send password reset email',
        cause: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppFailure.auth(
        code: 'no-current-user',
        message: 'No signed-in user to delete',
      );
    }
    try {
      await user.delete();
      await _googleSignIn.signOut();
    } on fb.FirebaseAuthException catch (e) {
      _log.warning('deleteAccount FirebaseAuthException: ${e.code}', e);
      throw AppFailure.auth(code: e.code, message: e.message);
    }
  }

  Future<void> _bootstrapUserDoc(fb.User user) async {
    try {
      final doc = _firestore.collection('users').doc(user.uid);
      final snap = await doc.get();
      if (!snap.exists) {
        await doc.set({
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignInAt': FieldValue.serverTimestamp(),
          'settings': {
            'reviewTime': '07:00',
            'dailyNewCardLimit': 20,
            'theme': 'system',
            'locale': 'vi',
          },
          'stats': {
            'streak': 0,
            'bestStreak': 0,
            'totalReviews': 0,
            'lastReviewedDate': null,
          },
        });
      } else {
        await doc.update({'lastSignInAt': FieldValue.serverTimestamp()});
      }
    } catch (e, st) {
      _log.warning('bootstrap user doc failed (non-fatal)', e, st);
    }
  }
}
