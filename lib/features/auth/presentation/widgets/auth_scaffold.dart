import 'package:flutter/material.dart';

import '../../../../app/theme/coolcare_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow = 'HOME AC CARE SERVICE',
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final String eyebrow;
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                    maxWidth: 390,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (showBackButton)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    key: const ValueKey('auth-back-button'),
                                    onPressed:
                                        onBack ??
                                        () => Navigator.of(context).maybePop(),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 21,
                                    ),
                                    tooltip: 'Back',
                                  ),
                                ),
                              const _Wordmark(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: CoolCareColors.primary,
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .65,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 25),
                        child,
                        const Spacer(),
                        const SizedBox(height: 28),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Cool',
        children: [
          TextSpan(
            text: 'Care',
            style: TextStyle(color: CoolCareColors.primary),
          ),
        ],
      ),
      style: TextStyle(
        color: CoolCareColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Cool comfort, every day.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CoolCareColors.mutedText, fontSize: 11),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 118,
          child: Divider(height: 1, color: CoolCareColors.border),
        ),
      ],
    );
  }
}
