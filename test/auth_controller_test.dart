import 'package:coolcare_mobile/features/auth/domain/auth_repository.dart';
import 'package:coolcare_mobile/features/auth/domain/auth_user.dart';
import 'package:coolcare_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login transitions to authenticated and exposes user', () async {
    final controller = AuthController(_FakeAuthRepository());
    await controller.initialize();

    final success = await controller.login(
      email: 'customer@coolcare.test',
      password: 'CoolCare@123',
    );

    expect(success, isTrue);
    expect(controller.status, AuthStatus.authenticated);
    expect(controller.user?.role, 'CUSTOMER');
  });

  test('logout clears authenticated user', () async {
    final controller = AuthController(_FakeAuthRepository());
    await controller.login(
      email: 'customer@coolcare.test',
      password: 'CoolCare@123',
    );

    await controller.logout();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.user, isNull);
  });

  test('register requires email verification before authenticating', () async {
    final controller = AuthController(_FakeAuthRepository());

    final success = await controller.register(
      fullName: 'Customer Demo',
      email: 'customer@coolcare.test',
      password: 'CoolCare@123',
    );

    expect(success, isTrue);
    expect(controller.status, isNot(AuthStatus.authenticated));
    expect(
      await controller.verifyRegistrationEmail(
        email: 'customer@coolcare.test',
        otp: '123456',
      ),
      isTrue,
    );
    expect(controller.status, AuthStatus.authenticated);
  });

  test('Google login authenticates the verified customer', () async {
    final controller = AuthController(_FakeAuthRepository());

    final success = await controller.loginWithGoogle();

    expect(success, isTrue);
    expect(controller.status, AuthStatus.authenticated);
    expect(controller.user?.email, 'customer@coolcare.test');
  });

  test('forgot password completes OTP and reset sequence', () async {
    final repository = _FakeAuthRepository();
    final controller = AuthController(repository);

    expect(
      await controller.requestPasswordReset('customer@coolcare.test'),
      isTrue,
    );
    final resetToken = await controller.verifyResetOtp(
      email: 'customer@coolcare.test',
      otp: '123456',
    );
    expect(resetToken, 'reset-token');
    expect(
      await controller.resetPassword(
        resetToken: resetToken!,
        newPassword: 'NewPassword@123',
      ),
      isTrue,
    );
    expect(repository.passwordReset, isTrue);
  });
}

class _FakeAuthRepository implements AuthRepository {
  bool passwordReset = false;

  static const _user = AuthUser(
    id: 'user-id',
    email: 'customer@coolcare.test',
    fullName: 'Customer Demo',
    role: 'CUSTOMER',
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return const AuthSession(token: 'token', user: _user);
  }

  @override
  Future<AuthSession> loginWithGoogle() async {
    return const AuthSession(token: 'google-token', user: _user);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {}

  @override
  Future<AuthSession> verifyRegistrationEmail({
    required String email,
    required String otp,
  }) async {
    return const AuthSession(token: 'token', user: _user);
  }

  @override
  Future<void> resendRegistrationEmailVerification({
    required String email,
  }) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    passwordReset = true;
  }

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    return 'reset-token';
  }
}
