import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../controllers/auth_controller.dart';
import '../validators/auth_validators.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loggedIn = await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (loggedIn && mounted) Navigator.of(context).pop();
  }

  Future<void> _submitGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearError();
    final loggedIn = await widget.controller.loginWithGoogle();
    if (loggedIn && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: context.tr('welcomeBack'),
      subtitle: context.tr('loginSubtitle'),
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
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'example@gmail.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: (value) =>
                        AuthValidators.email(value, context: context),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: context.tr('password'),
                    hintText: context.tr('enterPassword'),
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) => AuthValidators.requiredText(
                      value,
                      'validationPasswordField',
                      context: context,
                    ),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () {
                              widget.controller.clearError();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordPage(
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        context.tr('forgotPassword'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  AuthErrorBanner(message: widget.controller.errorMessage),
                  if (widget.controller.errorMessage != null)
                    const SizedBox(height: 14),
                  AuthSubmitButton(
                    label: context.tr('login'),
                    loading: widget.controller.isBusy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 18),
                  const _AuthDivider(),
                  const SizedBox(height: 18),
                  GoogleAuthButton(
                    label: context.tr('continueGoogle'),
                    loading: widget.controller.isBusy,
                    onPressed: _submitGoogle,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.tr('noAccount'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      TextButton(
                        onPressed: widget.controller.isBusy
                            ? null
                            : () {
                                widget.controller.clearError();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPage(
                                      controller: widget.controller,
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          context.tr('signUp'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const _ExploreServices(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExploreServices extends StatelessWidget {
  const _ExploreServices();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop('services'),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.north_east_rounded, size: 15),
          label: Text(
            context.tr('exploreServices'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.tr('or'),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
