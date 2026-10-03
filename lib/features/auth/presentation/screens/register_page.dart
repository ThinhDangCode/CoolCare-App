import 'package:flutter/material.dart';

import '../../domain/auth_validators.dart';
import '../auth_controller.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await widget.controller.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(
            controller: widget.controller,
            email: _emailController.text.trim().toLowerCase(),
          ),
        ),
      );
    }
  }

  Future<void> _submitGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearError();
    final success = await widget.controller.loginWithGoogle();
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: 'Create CoolCare Account',
        subtitle: 'Sign up to book services and track your appointments.',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'Enter full name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: AuthValidators.fullName,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'ban@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.newUsername,
                        AutofillHints.email,
                      ],
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Create Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hintText: 'Re-enter password',
                      icon: Icons.lock_reset_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) => AuthValidators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),
                    AuthErrorBanner(message: widget.controller.errorMessage),
                    if (widget.controller.errorMessage != null)
                      const SizedBox(height: 14),
                    AuthSubmitButton(
                      label: 'Create Account',
                      loading: widget.controller.isBusy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    const _AuthDivider(),
                    const SizedBox(height: 18),
                    GoogleAuthButton(
                      label: 'Sign up with Google',
                      loading: widget.controller.isBusy,
                      onPressed: _submitGoogle,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.controller.isBusy ? null : _backToLogin,
                      child: const Text('Already have an account? Log In'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
