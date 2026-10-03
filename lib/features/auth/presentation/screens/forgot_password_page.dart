import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/auth_validators.dart';
import '../auth_controller.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

enum _ResetStep { email, otp, password, success }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _ResetStep _step = _ResetStep.email;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    widget.controller.clearError();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _title => switch (_step) {
    _ResetStep.email => 'Forgot Password?',
    _ResetStep.otp => 'Email Verification',
    _ResetStep.password => 'Create New Password',
    _ResetStep.success => 'Password Updated',
  };

  String get _subtitle => switch (_step) {
    _ResetStep.email =>
      "Enter the email of your password account and we'll send a 6-digit reset code. Google-only accounts must continue with Google.",
    _ResetStep.otp =>
      'A 6-digit verification code has been sent to your email address.',
    _ResetStep.password => 'Enter your new password below.',
    _ResetStep.success => 'You can now log in with your new password.',
  };

  Future<void> _requestOtp() async {
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.controller.requestPasswordReset(
      _emailController.text,
    );
    if (success && mounted) {
      setState(() => _step = _ResetStep.otp);
    }
  }

  Future<void> _verifyOtp() async {
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = await widget.controller.verifyResetOtp(
      email: _emailController.text,
      otp: _otpController.text,
    );
    if (token != null && mounted) {
      setState(() {
        _resetToken = token;
        _step = _ResetStep.password;
      });
    }
  }

  Future<void> _resetPassword() async {
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false) || _resetToken == null) {
      return;
    }
    final success = await widget.controller.resetPassword(
      resetToken: _resetToken!,
      newPassword: _passwordController.text,
    );
    if (success && mounted) {
      setState(() => _step = _ResetStep.success);
    }
  }

  Future<void> _resendOtp() async {
    widget.controller.clearError();
    final success = await widget.controller.requestPasswordReset(
      _emailController.text,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi lại mã OTP.')));
    }
  }

  void _backToLogin() {
    widget.controller.clearError();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.controller.clearError();
      },
      child: AuthScaffold(
        showBackButton: true,
        onBack: _backToLogin,
        title: _title,
        subtitle: _subtitle,
        child: Form(
          key: _formKey,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (_step) {
                    _ResetStep.email => _emailStep(),
                    _ResetStep.otp => _otpStep(),
                    _ResetStep.password => _passwordStep(),
                    _ResetStep.success => _successStep(),
                  },
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'example@gmail.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: AuthValidators.email,
          onFieldSubmitted: (_) => _requestOtp(),
        ),
        const SizedBox(height: 18),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: 'Send Code',
          loading: widget.controller.isBusy,
          onPressed: _requestOtp,
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        _OtpInput(controller: _otpController, onCompleted: _verifyOtp),
        const SizedBox(height: 16),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: 'Verify Code',
          loading: widget.controller.isBusy,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 14),
        const Text(
          "Didn't receive the code?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        TextButton(
          onPressed: widget.controller.isBusy ? null : _resendOtp,
          child: const Text('Resend code', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _passwordController,
          label: 'New Password',
          hintText: 'Your new password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.password,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hintText: 'Confirm Password',
          icon: Icons.lock_reset_rounded,
          obscureText: true,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              AuthValidators.confirmPassword(value, _passwordController.text),
          onFieldSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 18),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: 'Reset Password',
          loading: widget.controller.isBusy,
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  Widget _successStep() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 76,
        ),
        const SizedBox(height: 20),
        const Text('Your password has been updated.'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}

class _OtpInput extends StatefulWidget {
  const _OtpInput({required this.controller, required this.onCompleted});

  final TextEditingController controller;
  final Future<void> Function() onCompleted;

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  late final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _changed(int index, String value) {
    widget.controller.text = _controllers.map((item) => item.text).join();
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (widget.controller.text.length == 6) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 43,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 13),
            ),
            onChanged: (value) => _changed(index, value),
            validator: index == 0
                ? (_) => AuthValidators.otp(widget.controller.text)
                : null,
          ),
        );
      }),
    );
  }
}
