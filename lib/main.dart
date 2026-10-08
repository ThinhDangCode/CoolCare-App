import 'package:flutter/material.dart';

import 'app/coolcare_app.dart';
import 'core/network/api_client.dart';
import 'core/network/cloudinary_image_uploader.dart';
import 'features/auth/data/api_auth_repository.dart';
import 'features/auth/data/secure_session_store.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Android Studio Emulator maps the host machine to 10.0.2.2.
    // Override with --dart-define=API_BASE_URL=... for a physical device
    // or another emulator provider such as Genymotion.
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  final repository = ApiAuthRepository(
    apiClient: ApiClient(
      baseUrl: baseUrl,
      fallbackBaseUrls: const [
        'http://10.0.2.2:3000/api',
        'http://10.0.3.2:3000/api',
      ],
    ),
    sessionStore: const SecureSessionStore(),
  );
  final authController = AuthController(
    repository,
    imageUploader: CloudinaryImageUploader.fromEnvironment(),
  )..initialize();

  runApp(CoolCareApp(authController: authController));
}
