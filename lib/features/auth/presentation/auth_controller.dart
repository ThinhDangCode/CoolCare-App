import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.initial;
  AuthUser? user;
  String? errorMessage;
  bool isBusy = false;

  Future<void> initialize() async {
    try {
      final session = await _repository.restoreSession();
      user = session?.user;
      status = session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) {
    return _authenticate(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<bool> loginWithGoogle() {
    return _authenticate(_repository.loginWithGoogle);
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _runOperation(
      () => _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> verifyRegistrationEmail({
    required String email,
    required String otp,
  }) {
    return _authenticate(
      () => _repository.verifyRegistrationEmail(email: email, otp: otp),
    );
  }

  Future<bool> resendRegistrationEmailVerification(String email) {
    return _runOperation(
      () => _repository.resendRegistrationEmailVerification(email: email),
    );
  }

  Future<bool> _authenticate(Future<AuthSession> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      user = session.user;
      status = AuthStatus.authenticated;
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
    status = AuthStatus.unauthenticated;
    isBusy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    await _repository.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    isBusy = false;
    notifyListeners();
  }

  Future<bool> requestPasswordReset(String email) async {
    return _runOperation(() => _repository.requestPasswordReset(email: email));
  }

  Future<String?> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resetToken = await _repository.verifyResetOtp(
        email: email,
        otp: otp,
      );
      isBusy = false;
      notifyListeners();
      return resetToken;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
    isBusy = false;
    notifyListeners();
    return null;
  }

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _runOperation(
      () => _repository.resetPassword(
        resetToken: resetToken,
        newPassword: newPassword,
      ),
    );
  }

  Future<bool> _runOperation(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
    isBusy = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }
}
