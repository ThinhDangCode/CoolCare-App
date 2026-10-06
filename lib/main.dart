import 'package:flutter/material.dart';

import 'app/coolcare_app.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/api_auth_repository.dart';
import 'features/auth/data/secure_session_store.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Genymotion maps the host machine to 10.0.3.2. Override with
    // --dart-define=API_BASE_URL=... when using another emulator/device.
    defaultValue: 'http://10.0.3.2:3000/api',
  );
  final repository = ApiAuthRepository(
    apiClient: ApiClient(baseUrl: baseUrl),
    sessionStore: const SecureSessionStore(),
  );
  final authController = AuthController(repository)..initialize();

  runApp(CoolCareApp(authController: authController));
}
