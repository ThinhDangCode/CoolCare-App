import 'package:coolcare_mobile/app/coolcare_app.dart';
import 'package:coolcare_mobile/app/preferences/app_preferences_controller.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
import 'package:coolcare_mobile/features/auth/controllers/auth_controller.dart';
import 'package:coolcare_mobile/features/auth/models/auth_user.dart';
import 'package:coolcare_mobile/features/auth/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts as guest and opens login on demand', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AuthController(_NoopAuthRepository());
    await controller.initialize();
    await tester.pumpWidget(_buildVietnameseApp(controller));

    expect(find.textContaining('Mát lạnh mỗi ngày'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('Explore Services opens the services tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AuthController(_NoopAuthRepository());
    await controller.initialize();
    await tester.pumpWidget(_buildVietnameseApp(controller));

    await tester.tap(find.text('Khám phá dịch vụ'));
    await tester.pumpAndSettle();

    expect(find.text('Dịch vụ máy lạnh'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated customer can open Account and Personal Profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = AuthUser(
      id: 'customer-1',
      email: 'nguyenvana@gmail.com',
      fullName: 'Nguyễn Văn A',
      role: 'CUSTOMER',
    );
    final controller = AuthController(
      _NoopAuthRepository(
        session: const AuthSession(token: 'test-token', user: user),
      ),
    );
    await controller.initialize();
    await tester.pumpWidget(_buildVietnameseApp(controller));

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn A'), findsOneWidget);

    await tester.tap(find.text('Xem hồ sơ →'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('nguyenvana@gmail.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replaced session closes account pages and shows a message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = AuthUser(
      id: 'customer-1',
      email: 'nguyenvana@gmail.com',
      fullName: 'Nguyễn Văn A',
      role: 'CUSTOMER',
    );
    final repository = _NoopAuthRepository(
      session: const AuthSession(token: 'test-token', user: user),
    );
    final controller = AuthController(repository);
    await controller.initialize();
    await tester.pumpWidget(_buildVietnameseApp(controller));
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem hồ sơ →'));
    await tester.pumpAndSettle();

    repository.refreshError = const ApiException(
      statusCode: 401,
      code: 'SESSION_REPLACED',
      message: 'Tài khoản đã đăng nhập trên thiết bị khác.',
    );
    await controller.refreshSession();
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(repository.localSessionCleared, isTrue);
    expect(find.text('Hồ sơ cá nhân'), findsNothing);
    expect(
      find.text('Tài khoản đã đăng nhập trên thiết bị khác.'),
      findsOneWidget,
    );
  });
}

CoolCareApp _buildVietnameseApp(AuthController controller) {
  final preferencesController = AppPreferencesController()
    ..locale = const Locale('vi');
  return CoolCareApp(
    authController: controller,
    preferencesController: preferencesController,
  );
}

class _NoopAuthRepository implements AuthRepository {
  _NoopAuthRepository({this.session});

  final AuthSession? session;
  ApiException? refreshError;
  bool localSessionCleared = false;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> loginWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearLocalSession() async {
    localSessionCleared = true;
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> verifyRegistrationEmail({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
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
  }) async {}

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> refreshSession() async {
    if (refreshError != null) throw refreshError!;
    return session!;
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async => 'token';

  @override
  Future<AuthUser> updateProfile({
    required String fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async => AuthUser(
    id: session?.user.id ?? 'user-id',
    email: session?.user.email ?? 'customer@coolcare.test',
    fullName: fullName,
    role: session?.user.role ?? 'CUSTOMER',
    phone: phone,
    dateOfBirth: dateOfBirth,
    gender: gender,
  );

  @override
  Future<AuthUser> updateAvatar({required String? avatarUrl}) async {
    final current = session?.user;
    return AuthUser(
      id: current?.id ?? 'user-id',
      email: current?.email ?? 'customer@coolcare.test',
      fullName: current?.fullName ?? 'Customer Demo',
      role: current?.role ?? 'CUSTOMER',
      phone: current?.phone,
      dateOfBirth: current?.dateOfBirth,
      gender: current?.gender,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}
