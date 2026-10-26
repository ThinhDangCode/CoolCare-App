import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/customer_ac_history.dart';

class AcHistoryRepository {
  AcHistoryRepository({ApiClient? apiClient, SecureSessionStore? sessionStore})
      : _api = apiClient ?? ApiClient.fromEnvironment(),
        _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }
    return session.token;
  }

  Future<List<AcUnitGroup>> units() async {
    final result = await _api.get(
      '/customer/ac-units',
      bearerToken: await _token(),
    );
    final items = (result['data'] as Map)['items'];
    if (items is! List) throw const FormatException('Invalid AC units response.');
    return items
        .whereType<Map>()
        .map((e) => AcUnitGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<AcHistoryPage> history(
    AcUnitGroup unit, {
    int page = 1,
    int limit = 20,
  }) async {
    if (page < 1 || limit < 1 || limit > 50) {
      throw ArgumentError('Invalid pagination');
    }
    final result = await _api.get(
      '/customer/ac-units/service-history',
      queryParameters: {
        'brandId': unit.brandId ?? 'none',
        'modelId': unit.modelId ?? 'none',
        'page': '$page',
        'limit': '$limit',
      },
      bearerToken: await _token(),
    );
    return AcHistoryPage.fromJson(Map<String, dynamic>.from(result['data'] as Map));
  }
}
