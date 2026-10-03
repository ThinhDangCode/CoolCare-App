import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';

class SecureSessionStore {
  const SecureSessionStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _tokenKey = 'coolcare_access_token';
  static const _userKey = 'coolcare_authenticated_user';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _userKey),
    ]);
    final token = values[0];
    final userJson = values[1];
    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      await clear();
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return AuthSession(token: token, user: AuthUser.fromJson(decoded));
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> write(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(key: _userKey, value: jsonEncode(session.user.toJson())),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
