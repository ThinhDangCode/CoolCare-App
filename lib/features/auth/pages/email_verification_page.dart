import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_strings.dart';
import '../controllers/auth_controller.dart';
import '../validators/auth_validators.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    required this.controller,
    required this.email,
    super.key,
  });

  final AuthController controller;
  final String email;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.clearError();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final verified = await widget.controller.verifyRegistrationEmail(
      email: widget.email,
      otp: _otpController.text,
    );
    if (verified && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _resend() async {
    widget.controller.clearError();
    final sent = await widget.controller.resendRegistrationEmailVerification(
      widget.email,
    );
    if (sent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi lại mã xác thực.')));
    }
  }

  void _backToRegister() {
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
        onBack: _backToRegister,
        title: context.tr('verifyEmail'),
        subtitle: "${context.tr('enterCodeSentTo')} ${widget.email}.",
        child: Form(
          key: _formKey,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _otpController,
                  label: context.tr('verificationCode'),
                  hintText: context.tr('sixDigitCode'),
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: AuthValidators.otp,
                  onFieldSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 18),
                AuthErrorBanner(message: widget.controller.errorMessage),
                if (widget.controller.errorMessage != null)
                  const SizedBox(height: 14),
                AuthSubmitButton(
                  label: context.tr('verifyEmail'),
                  loading: widget.controller.isBusy,
                  onPressed: _verify,
                ),
                TextButton(
                  onPressed: widget.controller.isBusy ? null : _resend,
                  child: Text(context.tr('resendCode')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
