import 'package:flutter/material.dart';

/// Determines whether the form operates in sign-in or register mode.
enum EmailAuthMode { signIn, register }

/// A stateful form widget handling both sign-in and registration flows.
///
/// Owns [TextEditingController]s for email and password. The parent screen
/// wires [onSubmit] to the appropriate repository method.
class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({
    required this.onSubmit,
    required this.onForgotPassword,
    super.key,
    this.loading = false,
  });

  final void Function({
    required EmailAuthMode mode,
    required String email,
    required String password,
  }) onSubmit;
  final void Function(String email) onForgotPassword;
  final bool loading;

  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  EmailAuthMode _mode = EmailAuthMode.signIn;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == EmailAuthMode.signIn
          ? EmailAuthMode.register
          : EmailAuthMode.signIn;
      _formKey.currentState?.reset();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      mode: _mode,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Vui lòng nhập email.';
    if (!trimmed.contains('@')) return 'Email không hợp lệ.';
    return null;
  }

  String? _validatePassword(String? value) {
    final pw = value ?? '';
    if (_mode == EmailAuthMode.register) {
      if (pw.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    } else {
      if (pw.isEmpty) return 'Vui lòng nhập mật khẩu.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == EmailAuthMode.signIn;
    final disabled = widget.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            enabled: !disabled,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),

          // Password field
          TextFormField(
            controller: _passwordController,
            enabled: !disabled,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: disabled ? null : (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: disabled
                    ? null
                    : () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
              ),
            ),
            validator: _validatePassword,
          ),

          // Forgot password — sign-in mode only
          if (isSignIn) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: disabled
                    ? null
                    : () => widget.onForgotPassword(
                          _emailController.text.trim(),
                        ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
          ] else
            const SizedBox(height: 12),

          // Submit button
          FilledButton(
            onPressed: disabled ? null : _submit,
            child: Text(isSignIn ? 'Đăng nhập' : 'Đăng ký'),
          ),
          const SizedBox(height: 8),

          // Mode toggle
          TextButton(
            onPressed: disabled ? null : _toggleMode,
            child: Text(
              isSignIn
                  ? 'Chưa có tài khoản? Đăng ký'
                  : 'Đã có tài khoản? Đăng nhập',
            ),
          ),
        ],
      ),
    );
  }
}
