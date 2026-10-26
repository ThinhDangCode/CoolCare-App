import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'theme/coolcare_theme.dart';
import 'preferences/app_preferences_controller.dart';

class CoolCareApp extends StatelessWidget {
  CoolCareApp({
    required this.authController,
    AppPreferencesController? preferencesController,
    super.key,
  }) : preferencesController =
           preferencesController ?? AppPreferencesController();

  final AuthController authController;
  final AppPreferencesController preferencesController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferencesController,
      builder: (context, _) => AppPreferencesScope(
        notifier: preferencesController,
        child: MaterialApp(
          title: 'CoolCare',
          debugShowCheckedModeBanner: false,
          theme: CoolCareTheme.light,
          darkTheme: CoolCareTheme.dark,
          themeMode: preferencesController.themeMode,
          locale: preferencesController.locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ListenableBuilder(
            listenable: authController,
            builder: (context, _) {
              return switch (authController.status) {
                AuthStatus.initial || AuthStatus.loading => const _SplashPage(),
                AuthStatus.authenticated || AuthStatus.unauthenticated =>
                  HomePage(controller: authController),
              };
            },
          ),
        ),
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
