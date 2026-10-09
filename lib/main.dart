import 'package:flutter/material.dart';

import 'app/coolcare_app.dart';
import 'core/network/api_client.dart';
import 'core/network/cloudinary_image_uploader.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/repositories/api_auth_repository.dart';
import 'features/auth/services/secure_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = ApiAuthRepository(
    apiClient: ApiClient.fromEnvironment(),
    sessionStore: const SecureSessionStore(),
  );
  final authController = AuthController(
    repository,
    imageUploader: CloudinaryImageUploader.fromEnvironment(),
  )..initialize();

  runApp(CoolCareApp(authController: authController));
}
