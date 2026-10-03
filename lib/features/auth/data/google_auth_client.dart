import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_exception.dart';

class GoogleAuthClient {
  GoogleAuthClient({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '946372796403-p9k2467md56604o4cbu8jijhpidlmdpi.apps.googleusercontent.com',
  );

  final GoogleSignIn _signIn;
  Future<void>? _initialization;

  Future<String> requestIdToken() async {
    if (_serverClientId.isEmpty) {
      throw const ApiException(
        code: 'GOOGLE_NOT_CONFIGURED',
        message: 'Google Sign-In chưa được cấu hình cho ứng dụng này.',
      );
    }

    try {
      await (_initialization ??= _signIn.initialize(
        serverClientId: _serverClientId,
      ));
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          code: 'GOOGLE_TOKEN_MISSING',
          message: 'Không nhận được mã xác thực từ Google. Vui lòng thử lại.',
        );
      }
      return idToken;
    } on ApiException {
      rethrow;
    } on GoogleSignInException catch (error) {
      assert(() {
        debugPrint(
          'Google Sign-In failed: code=${error.code.name}, '
          'description=${error.description ?? 'none'}',
        );
        return true;
      }());
      throw ApiException(
        code: 'GOOGLE_SIGN_IN_${error.code.name}',
        message: _messageFor(error.code),
      );
    } catch (_) {
      throw const ApiException(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: 'Không thể đăng nhập bằng Google. Vui lòng thử lại.',
      );
    }
  }

  String _messageFor(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => 'Bạn đã hủy đăng nhập Google.',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Cấu hình Google Android chưa đúng. Kiểm tra package name và SHA-1 của Android OAuth client.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Dịch vụ Google trên thiết bị chưa sẵn sàng. Vui lòng thử lại sau.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Không thể mở màn hình chọn tài khoản Google. Vui lòng thử lại.',
      GoogleSignInExceptionCode.interrupted =>
        'Đăng nhập Google bị gián đoạn. Vui lòng thử lại.',
      GoogleSignInExceptionCode.userMismatch =>
        'Tài khoản Google đã chọn không khớp. Vui lòng chọn lại.',
      _ => 'Không thể đăng nhập bằng Google. Vui lòng thử lại.',
    };
  }
}
