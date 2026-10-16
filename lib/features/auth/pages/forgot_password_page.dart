import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_strings.dart';
import '../controllers/auth_controller.dart';
import '../validators/auth_validators.dart';
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
    _ResetStep.email => context.tr('forgotPasswordTitle'),
    _ResetStep.otp => context.tr('emailVerification'),
    _ResetStep.password => context.tr('createNewPassword'),
    _ResetStep.success => context.tr('passwordUpdated'),
  };

  String get _subtitle => switch (_step) {
    _ResetStep.email => context.tr('resetEmailHint'),
    _ResetStep.otp => context.tr('otpSentHint'),
    _ResetStep.password => context.tr('newPasswordHint'),
    _ResetStep.success => context.tr('passwordUpdatedHint'),
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
      ).showSnackBar(SnackBar(content: Text(context.tr('otpResent'))));
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
          validator: (value) => AuthValidators.email(value, context: context),
          onFieldSubmitted: (_) => _requestOtp(),
        ),
        const SizedBox(height: 18),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: context.tr('sendCode'),
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
        Text(
          context.tr('verificationCode'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        _OtpInput(controller: _otpController, onCompleted: _verifyOtp),
        const SizedBox(height: 16),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: context.tr('verifyCode'),
          loading: widget.controller.isBusy,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('noCode'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        TextButton(
          onPressed: widget.controller.isBusy ? null : _resendOtp,
          child: Text(
            context.tr('resendCode'),
            style: const TextStyle(fontSize: 11),
          ),
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
          label: context.tr('newPassword'),
          hintText: context.tr('newPasswordHint'),
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              AuthValidators.password(value, context: context),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: _confirmPasswordController,
          label: context.tr('confirmPassword'),
          hintText: context.tr('confirmPassword'),
          icon: Icons.lock_reset_rounded,
          obscureText: true,
          textInputAction: TextInputAction.done,
          validator: (value) => AuthValidators.confirmPassword(
            value,
            _passwordController.text,
            context: context,
          ),
          onFieldSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 18),
        AuthErrorBanner(message: widget.controller.errorMessage),
        if (widget.controller.errorMessage != null) const SizedBox(height: 14),
        AuthSubmitButton(
          label: context.tr('resetPassword'),
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
        Text(context.tr('passwordUpdatedSuccess')),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('backToLogin')),
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
                ? (_) => AuthValidators.otp(
                    widget.controller.text,
                    context: context,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
