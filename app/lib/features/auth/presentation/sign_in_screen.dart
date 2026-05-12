import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';
import 'package:zeno/features/auth/presentation/widgets/email_sign_in_form.dart';
import 'package:zeno/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Maps Firebase auth error codes to human-readable Vietnamese messages.
String _humanMessageFor(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Email không hợp lệ.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email hoặc mật khẩu không đúng.';
    case 'email-already-in-use':
      return 'Email này đã được đăng ký.';
    case 'weak-password':
      return 'Mật khẩu quá yếu (cần >= 6 ký tự).';
    case 'network-request-failed':
      return 'Lỗi mạng. Kiểm tra kết nối rồi thử lại.';
    case 'too-many-requests':
      return 'Quá nhiều lần thử. Vui lòng đợi một chút.';
    case 'cancelled':
      return 'Đã hủy đăng nhập.';
    default:
      return 'Đăng nhập thất bại ($code). Thử lại sau.';
  }
}

/// The main authentication screen composing logo, email form, and Google
/// sign-in into a single scrollable layout.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _emailLoading = false;
  bool _googleLoading = false;
  bool _forgotLoading = false;

  bool get _anyLoading => _emailLoading || _googleLoading || _forgotLoading;

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Translates an [AppFailure] into a SnackBar message.
  ///
  /// Pass [ignoreCode] to silently swallow a specific auth code
  /// (e.g. `'cancelled'` for Google sign-in).
  void _showFailure(AppFailure failure, {String? ignoreCode}) {
    failure.whenOrNull(
      auth: (code, _) {
        if (code == ignoreCode) return;
        _showSnackBar(_humanMessageFor(code));
      },
      network: (_) {
        _showSnackBar(_humanMessageFor('network-request-failed'));
      },
    );
    // AppFailure variants not matched above fall through silently; any
    // truly unexpected failure is handled by the surrounding catch clause.
  }

  Future<void> _handleEmailSubmit({
    required EmailAuthMode mode,
    required String email,
    required String password,
  }) async {
    setState(() => _emailLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (mode == EmailAuthMode.signIn) {
        await repo.signInWithEmail(email: email, password: password);
      } else {
        await repo.registerWithEmail(email: email, password: password);
      }
      // Router redirect handles navigation on success.
    } on AppFailure catch (f) {
      _showFailure(f);
    } catch (_) {
      _showSnackBar(_humanMessageFor('unknown'));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      // Router redirect handles navigation on success.
    } on AppFailure catch (f) {
      _showFailure(f, ignoreCode: 'cancelled');
    } catch (_) {
      _showSnackBar(_humanMessageFor('unknown'));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleForgotPassword(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Text(
          email.isEmpty
              ? 'Nhập email bên dưới rồi thử lại để nhận '
                  'link đặt lại mật khẩu.'
              : 'Gửi link đặt lại mật khẩu đến:\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          if (email.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Gửi'),
            ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (email.isEmpty) return;

    setState(() => _forgotLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(email);
      _showSnackBar('Đã gửi email đặt lại mật khẩu đến $email.');
    } on AppFailure catch (f) {
      _showFailure(f);
    } catch (_) {
      _showSnackBar(_humanMessageFor('unknown'));
    } finally {
      if (mounted) setState(() => _forgotLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            // Ensure the column fills at least the viewport height so
            // Spacers behave correctly even when content is short.
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 64),

                  // --- Logo + tagline ---
                  Text(
                    'Zeno',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học từ bất kỳ thứ gì.\nNhớ mãi mãi.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // --- Email form ---
                  EmailSignInForm(
                    onSubmit: _handleEmailSubmit,
                    onForgotPassword: _handleForgotPassword,
                    loading: _anyLoading,
                  ),

                  const SizedBox(height: 24),

                  // --- "hoặc" divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'hoặc',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- Google Sign-In ---
                  GoogleSignInButton(
                    onPressed:
                        _anyLoading ? () {} : _handleGoogleSignIn,
                    loading: _googleLoading,
                  ),

                  const Spacer(),

                  // --- Footer ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Bằng việc đăng nhập, bạn đồng ý với Điều khoản '
                      '& Chính sách bảo mật',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
