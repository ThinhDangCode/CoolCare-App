import 'auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> loginWithGoogle();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AuthSession> verifyRegistrationEmail({
    required String email,
    required String otp,
  });

  Future<void> resendRegistrationEmailVerification({required String email});

  Future<void> logout();

  Future<void> requestPasswordReset({required String email});

  Future<String> verifyResetOtp({required String email, required String otp});

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
