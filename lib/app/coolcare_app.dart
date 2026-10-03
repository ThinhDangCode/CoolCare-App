import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'theme/coolcare_theme.dart';

class CoolCareApp extends StatelessWidget {
  const CoolCareApp({required this.authController, super.key});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoolCare',
      debugShowCheckedModeBanner: false,
      theme: CoolCareTheme.light,
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          return switch (authController.status) {
            AuthStatus.initial || AuthStatus.loading => const _SplashPage(),
            AuthStatus.authenticated ||
            AuthStatus.unauthenticated => HomePage(controller: authController),
          };
        },
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ac_unit_rounded,
              color: CoolCareColors.primary,
              size: 52,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
