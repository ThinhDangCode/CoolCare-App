import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'google_auth_client.dart';
import 'secure_session_store.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient apiClient,
    required SecureSessionStore sessionStore,
    GoogleAuthClient? googleAuthClient,
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore,
       _googleAuthClient = googleAuthClient ?? GoogleAuthClient();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;
  final GoogleAuthClient _googleAuthClient;

  @override
  Future<AuthSession?> restoreSession() => _sessionStore.read();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return _saveSession(payload);
  }

  @override
  Future<AuthSession> loginWithGoogle() async {
    final idToken = await _googleAuthClient.requestIdToken();
    final payload = await _apiClient.post(
      '/auth/google',
      body: {'idToken': idToken},
    );
    return _saveSession(payload);
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
  }

  @override
  Future<AuthSession> verifyRegistrationEmail({
    required String email,
    required String otp,
  }) async {
    final payload = await _apiClient.post(
      '/auth/register/verify-email',
      body: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );
    return _saveSession(payload);
  }

  @override
  Future<void> resendRegistrationEmailVerification({
    required String email,
  }) async {
    await _apiClient.post(
      '/auth/register/resend-verification',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  AuthSession _parseSession(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Phản hồi đăng nhập thiếu dữ liệu.',
      );
    }
    final token = data['token']?.toString();
    final userJson = data['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Phản hồi đăng nhập không hợp lệ.',
      );
    }
    return AuthSession(token: token, user: AuthUser.fromJson(userJson));
  }

  Future<AuthSession> _saveSession(Map<String, dynamic> payload) async {
    final session = _parseSession(payload);
    await _sessionStore.write(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final session = await _sessionStore.read();
    try {
      if (session != null) {
        await _apiClient.post('/auth/logout', bearerToken: session.token);
      }
    } on ApiException {
      // Local credentials must always be removed, even when the server is offline.
    } finally {
      await _sessionStore.clear();
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await _apiClient.post(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final payload = await _apiClient.post(
      '/auth/forgot-password/verify',
      body: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );
    final data = payload['data'];
    final resetToken = data is Map<String, dynamic>
        ? data['resetToken']?.toString()
        : null;
    if (resetToken == null || resetToken.isEmpty) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Không nhận được quyền đặt lại mật khẩu.',
      );
    }
    return resetToken;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/forgot-password/reset',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }
}
